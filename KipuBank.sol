// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank
/// @notice Bóveda de ETH con límite de retiro y límite global
contract KipuBank {

    // =========================
    // ERRORES
    // =========================
    /// @notice Error si el depósito es 0
    error ZeroDeposit();
    /// @notice Error si el retiro es 0
    error ZeroWithdrawal();
    /// @notice Error si el retiro supera el límite
    error OverWithdrawal(uint256 requested, uint256 limit);
    /// @notice Error si el usuario no tiene fondos suficientes
    error NoFunds(uint256 requested, uint256 available);
    /// @notice Error si se excede el límite global
    error BankCapExceeded(uint256 wouldBe, uint256 cap);
    /// @notice Error si falla la transferencia
    error TransferFailed();
    /// @notice Error si se detecta reentrancy
    error ReentrancyDetected();
    /// @notice Error si los límites iniciales son 0
    error InvalidLimit();

    // =========================
    // VARIABLES INMUTABLES
    // =========================
    /// @notice Límite máximo por retiro
    uint256 public immutable WITHDRAWAL_LIMIT;
    /// @notice Límite global de la bóveda
    uint256 public immutable BANK_CAP;

    // =========================
    // VARIABLES DE ALMACENAMIENTO
    // =========================
    /// @notice Balance de cada usuario
    mapping(address => uint256) private balances;
    /// @notice Total de ETH en la bóveda
    uint256 private totalVaultBalance;
    /// @notice Contador total de depósitos
    uint256 private totalDepositCount;
    /// @notice Contador total de retiros
    uint256 private totalWithdrawalCount;
    /// @notice Depósitos por usuario
    mapping(address => uint256) private userDepositCount;
    /// @notice Retiros por usuario
    mapping(address => uint256) private userWithdrawalCount;
    /// @notice Reentrancy Guard
    uint256 private locked = 1;

    // =========================
    // EVENTOS
    // =========================
    /// @notice Emitido al depositar ETH
    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    /// @notice Emitido al retirar ETH
    event Withdrawn(address indexed user, uint256 amount, uint256 newBalance);

    // =========================
    // MODIFICADOR
    // =========================
    modifier nonReentrant() {
        if (locked != 1) revert ReentrancyDetected();
        locked = 2;
        _;
        locked = 1;
    }

    // =========================
    // CONSTRUCTOR
    // =========================
    /// @notice Inicializa límites de retiro y bóveda
    constructor(uint256 withdrawalLimit, uint256 bankCap) {
        if (withdrawalLimit == 0 || bankCap == 0) revert InvalidLimit();
        WITHDRAWAL_LIMIT = withdrawalLimit;
        BANK_CAP = bankCap;
    }

    // =========================
    // FUNCIONES EXTERNAS
    // =========================
    /// @notice Depositar ETH
    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert ZeroDeposit();
        uint256 newTotal = totalVaultBalance + msg.value;
        if (newTotal > BANK_CAP) revert BankCapExceeded(newTotal, BANK_CAP);

        // Se actualizan balances y contadores
        balances[msg.sender] += msg.value;
        totalVaultBalance += msg.value;
        totalDepositCount++;
        userDepositCount[msg.sender]++;

        emit Deposited(msg.sender, msg.value, balances[msg.sender]);
    }

    /// @notice Retirar ETH
    /// @param amount Cantidad a retirar
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroWithdrawal();
        if (amount > WITHDRAWAL_LIMIT) revert OverWithdrawal(amount, WITHDRAWAL_LIMIT);
        if (amount > balances[msg.sender]) revert NoFunds(amount, balances[msg.sender]);

        // Se actualizan balances y contadores 
        balances[msg.sender] -= amount;
        totalVaultBalance -= amount;
        totalWithdrawalCount++;
        userWithdrawalCount[msg.sender]++;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit Withdrawn(msg.sender, amount, balances[msg.sender]);
    }

    // =========================
    // FUNCIONES DE VISTA
    // =========================
    /// @notice Devuelve balance de usuario
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /// @notice Devuelve estadísticas globales
    function getVaultStats() external view returns (uint256 deposits, uint256 withdrawals) {
        return (totalDepositCount, totalWithdrawalCount);
    }

    /// @notice Devuelve estadísticas de un usuario
    function getUserStats(address user) external view returns (uint256 deposits, uint256 withdrawals) {
        return (userDepositCount[user], userWithdrawalCount[user]);
    }

    // =========================
    // RECEIVE / FALLBACK
    // =========================
    receive() external payable nonReentrant {
        if (msg.value == 0) revert ZeroDeposit();
        uint256 newTotal = totalVaultBalance + msg.value;
        if (newTotal > BANK_CAP) revert BankCapExceeded(newTotal, BANK_CAP);

        // Se actualizan balances y contadores 
        balances[msg.sender] += msg.value;
        totalVaultBalance += msg.value;
        totalDepositCount++;
        userDepositCount[msg.sender]++;

        emit Deposited(msg.sender, msg.value, balances[msg.sender]);
    }

    fallback() external payable {
        revert("Funcion no existe");
    }

    // =========================
    // FUNCION PRIVADA
    // =========================
    /// @notice Devuelve si un usuario tiene fondos > 0
    function _hasFunds(address user) private view returns (bool) {
        return balances[user] > 0;
    }
}
