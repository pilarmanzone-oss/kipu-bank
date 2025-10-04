// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBank
 * @author Pilar
 * @notice Contrato de bóveda personal que permite a los usuarios depositar y retirar ETH con límites
 * @dev Implementa límites por transacción, límite global y protección contra reentrancy
 */
contract KipuBank {
    // ============================================
    // ERRORES PERSONALIZADOS
    // ============================================
    
    /// @notice Error cuando el depósito es cero
    error DepositCannotBeZero();
    
    /// @notice Error cuando el retiro excede el límite por transacción
    /// @param requested Cantidad solicitada
    /// @param limit Límite permitido
    error WithdrawalExceedsLimit(uint256 requested, uint256 limit);
    
    /// @notice Error cuando el usuario no tiene fondos suficientes
    /// @param requested Cantidad solicitada
    /// @param available Fondos disponibles
    error InsufficientBalance(uint256 requested, uint256 available);
    
    /// @notice Error cuando el depósito excedería el límite global del banco
    /// @param wouldBe Total que resultaría
    /// @param cap Límite máximo del banco
    error BankCapExceeded(uint256 wouldBe, uint256 cap);
    
    /// @notice Error cuando la transferencia de ETH falla
    error TransferFailed();
    
    /// @notice Error cuando el retiro es cero
    error WithdrawalCannotBeZero();
    
    /// @notice Error cuando el límite del banco es cero en el constructor
    error InvalidBankCap();
    
    /// @notice Error cuando el límite de retiro es cero en el constructor
    error InvalidWithdrawalLimit();
    
    /// @notice Error cuando se detecta un ataque de reentrancy
    error ReentrancyDetected();

    // ============================================
    // VARIABLES DE ESTADO
    // ============================================
    
    /// @notice Límite máximo de retiro por transacción (inmutable)
    /// @dev Establecido en el constructor, no puede ser modificado
    uint256 public immutable WITHDRAWAL_LIMIT;
    
    /// @notice Límite global de depósitos del banco (inmutable)
    /// @dev Suma total de todos los depósitos no puede exceder este valor
    uint256 public immutable BANK_CAP;
    
    /// @notice Mapping de dirección a balance del usuario
    /// @dev Almacena el balance de ETH de cada usuario en el banco
    mapping(address => uint256) private s_userBalances;
    
    /// @notice Total de ETH depositado en el banco
    /// @dev Se actualiza con cada depósito y retiro exitoso
    uint256 private s_totalDeposits;
    
    /// @notice Contador total de depósitos realizados
    /// @dev Incrementa con cada depósito exitoso
    uint256 private s_totalDepositCount;
    
    /// @notice Contador total de retiros realizados
    /// @dev Incrementa con cada retiro exitoso
    uint256 private s_totalWithdrawalCount;
    
    /// @notice Mapping de dirección a número de depósitos del usuario
    /// @dev Rastrea cuántos depósitos ha hecho cada usuario
    mapping(address => uint256) private s_userDepositCount;
    
    /// @notice Mapping de dirección a número de retiros del usuario
    /// @dev Rastrea cuántos retiros ha hecho cada usuario
    mapping(address => uint256) private s_userWithdrawalCount;
    
    /// @notice Guard para prevenir reentrancy
    /// @dev 1 = no locked, 2 = locked
    uint256 private s_locked = 1;

    // ============================================
    // EVENTOS
    // ============================================
    
    /// @notice Emitido cuando un usuario realiza un depósito exitoso
    /// @param user Dirección del usuario que deposita
    /// @param amount Cantidad de ETH depositada
    /// @param newBalance Nuevo balance del usuario después del depósito
    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    
    /// @notice Emitido cuando un usuario realiza un retiro exitoso
    /// @param user Dirección del usuario que retira
    /// @param amount Cantidad de ETH retirada
    /// @param remainingBalance Balance restante del usuario después del retiro
    event Withdrawn(address indexed user, uint256 amount, uint256 remainingBalance);

    // ============================================
    // MODIFICADORES
    // ============================================
    
    /// @notice Previene ataques de reentrancy
    modifier nonReentrant() {
        if (s_locked != 1) {
            revert ReentrancyDetected();
        }
        s_locked = 2;
        _;
        s_locked = 1;
    }
    
    /// @notice Verifica que el monto no sea cero
    /// @param amount Cantidad a verificar
    modifier notZero(uint256 amount) {
        if (amount == 0) {
            revert DepositCannotBeZero();
        }
        _;
    }
    
    /// @notice Verifica que el retiro no exceda el límite por transacción
    /// @param amount Cantidad a retirar
    modifier withinWithdrawalLimit(uint256 amount) {
        if (amount > WITHDRAWAL_LIMIT) {
            revert WithdrawalExceedsLimit(amount, WITHDRAWAL_LIMIT);
        }
        _;
    }
    
    /// @notice Verifica que el usuario tenga suficiente balance
    /// @param amount Cantidad a verificar contra el balance
    modifier hasSufficientBalance(uint256 amount) {
        uint256 userBalance = s_userBalances[msg.sender];
        if (amount > userBalance) {
            revert InsufficientBalance(amount, userBalance);
        }
        _;
    }

    // ============================================
    // CONSTRUCTOR
    // ============================================
    
    /**
     * @notice Inicializa el contrato con los límites especificados
     * @param _withdrawalLimit Límite máximo por retiro en wei
     * @param _bankCap Límite global de depósitos del banco en wei
     * @dev Ambos valores deben ser mayores a cero
     */
    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        if (_withdrawalLimit == 0) {
            revert InvalidWithdrawalLimit();
        }
        if (_bankCap == 0) {
            revert InvalidBankCap();
        }
        
        WITHDRAWAL_LIMIT = _withdrawalLimit;
        BANK_CAP = _bankCap;
    }

    // ============================================
    // FUNCIONES EXTERNAS
    // ============================================
    
    /**
     * @notice Permite a los usuarios depositar ETH en su bóveda personal
     * @dev El depósito no debe exceder el límite global del banco
     * @dev Emite evento Deposited en caso de éxito
     */
    function deposit() external payable nonReentrant notZero(msg.value) {
        // Checks
        uint256 newTotalDeposits = s_totalDeposits + msg.value;
        if (newTotalDeposits > BANK_CAP) {
            revert BankCapExceeded(newTotalDeposits, BANK_CAP);
        }
        
        // Effects
        s_userBalances[msg.sender] += msg.value;
        s_totalDeposits = newTotalDeposits;
        s_totalDepositCount++;
        s_userDepositCount[msg.sender]++;
        
        // Events
        emit Deposited(msg.sender, msg.value, s_userBalances[msg.sender]);
    }
    
    /**
     * @notice Permite a los usuarios retirar ETH de su bóveda personal
     * @param amount Cantidad de ETH a retirar en wei
     * @dev El retiro no debe exceder el límite por transacción ni el balance del usuario
     * @dev Emite evento Withdrawn en caso de éxito
     * @dev Protegido contra reentrancy con nonReentrant modifier
     */
    function withdraw(uint256 amount) 
        external 
        nonReentrant
        notZero(amount)
        withinWithdrawalLimit(amount)
        hasSufficientBalance(amount)
    {
        // Effects (antes de interactions - patrón CEI)
        s_userBalances[msg.sender] -= amount;
        s_totalDeposits -= amount;
        s_totalWithdrawalCount++;
        s_userWithdrawalCount[msg.sender]++;
        
        // Interactions
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
        
        // Events
        emit Withdrawn(msg.sender, amount, s_userBalances[msg.sender]);
    }

    // ============================================
    // FUNCIONES PÚBLICAS DE VISTA
    // ============================================
    
    /**
     * @notice Obtiene el balance de ETH de un usuario específico
     * @param user Dirección del usuario a consultar
     * @return balance Balance actual del usuario en wei
     */
    function getBalance(address user) external view returns (uint256 balance) {
        return s_userBalances[user];
    }
    
    /**
     * @notice Obtiene el total de depósitos actuales en el banco
     * @return total Total de ETH depositado en el banco en wei
     */
    function getTotalDeposits() external view returns (uint256 total) {
        return s_totalDeposits;
    }
    
    /**
     * @notice Obtiene las estadísticas globales del banco
     * @return totalDeposits Total de ETH en el banco
     * @return depositCount Número total de depósitos realizados
     * @return withdrawalCount Número total de retiros realizados
     */
    function getBankStatistics() 
        external 
        view 
        returns (
            uint256 totalDeposits,
            uint256 depositCount,
            uint256 withdrawalCount
        ) 
    {
        return (s_totalDeposits, s_totalDepositCount, s_totalWithdrawalCount);
    }
    
    /**
     * @notice Obtiene las estadísticas de un usuario específico
     * @param user Dirección del usuario a consultar
     * @return balance Balance actual del usuario
     * @return deposits Número de depósitos realizados
     * @return withdrawals Número de retiros realizados
     */
    function getUserStatistics(address user)
        external
        view
        returns (
            uint256 balance,
            uint256 deposits,
            uint256 withdrawals
        )
    {
        return (
            s_userBalances[user],
            s_userDepositCount[user],
            s_userWithdrawalCount[user]
        );
    }
    
    /**
     * @notice Verifica si un depósito específico es permitido
     * @param amount Cantidad a verificar
     * @return allowed True si el depósito no excede el límite del banco
     */
    function isDepositAllowed(uint256 amount) external view returns (bool allowed) {
        return (s_totalDeposits + amount) <= BANK_CAP;
    }

    // ============================================
    // FUNCIONES PRIVADAS
    // ============================================
    
    /**
     * @notice Calcula el espacio disponible para depósitos en el banco
     * @dev Función privada usada internamente para cálculos
     * @return available Cantidad de ETH que aún puede ser depositada
     */
    function _getAvailableDepositSpace() private view returns (uint256 available) {
        if (s_totalDeposits >= BANK_CAP) {
            return 0;
        }
        return BANK_CAP - s_totalDeposits;
    }
    
    /**
     * @notice Valida si una dirección tiene fondos
     * @dev Función privada para verificaciones internas
     * @param user Dirección a verificar
     * @return hasFunds True si el usuario tiene balance mayor a cero
     */
    function _userHasFunds(address user) private view returns (bool hasFunds) {
        return s_userBalances[user] > 0;
    }

    // ============================================
    // FUNCIONES DE RECEPCIÓN
    // ============================================
    
    /**
     * @notice Función receive para manejar transferencias directas de ETH
     * @dev Llama a la función deposit internamente
     */
    receive() external payable nonReentrant {
        // Checks
        if (msg.value == 0) {
            revert DepositCannotBeZero();
        }
        
        uint256 newTotalDeposits = s_totalDeposits + msg.value;
        if (newTotalDeposits > BANK_CAP) {
            revert BankCapExceeded(newTotalDeposits, BANK_CAP);
        }
        
        // Effects
        s_userBalances[msg.sender] += msg.value;
        s_totalDeposits = newTotalDeposits;
        s_totalDepositCount++;
        s_userDepositCount[msg.sender]++;
        
        // Events
        emit Deposited(msg.sender, msg.value, s_userBalances[msg.sender]);
    }
    
    /**
     * @notice Función fallback para rechazar llamadas no válidas
     * @dev Revierte cualquier llamada que no coincida con una función
     */
    fallback() external payable {
        revert("KipuBank: funcion no existe");
    }
}
