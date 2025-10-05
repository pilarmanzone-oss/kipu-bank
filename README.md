# KipuBank

**KipuBank** es un contrato inteligente en Solidity que permite **guardar y retirar ETH** de manera segura, con límites configurables y protección contra reentrancy.

---

## Características principales

- **Depósitos seguros**: se puede depositar ETH mediante la función `deposit()` o enviando ETH directamente al contrato (`receive()`).  
- **Retiros controlados**: los retiros se limitan a `WITHDRAWAL_LIMIT` por transacción.  
- **Límite global**: la bóveda no puede exceder `BANK_CAP`.  
- **Eventos**: se emiten `Deposited` y `Withdrawn` para cada operación exitosa.  
- **Registro de operaciones**: se llevan contadores de depósitos y retiros totales y por usuario.  
- **Protección contra reentrancy**: mediante el modificador `nonReentrant`.  
- **Errores personalizados**: `ZeroDeposit`, `ZeroWithdrawal`, `OverWithdrawal`, `NoFunds`, `BankCapExceeded`, `TransferFailed`, `ReentrancyDetected`, `InvalidLimit`.

---

## Variables importantes

- `WITHDRAWAL_LIMIT`: máximo ETH por retiro.  
- `BANK_CAP`: máximo total de ETH en la bóveda.  
- `balances`: mapping de balances por usuario.  
- `totalVaultBalance`: total de ETH en la bóveda.  
- `totalDepositCount` / `totalWithdrawalCount`: contadores globales.  
- `userDepositCount` / `userWithdrawalCount`: contadores por usuario.

---

## Cómo usar en Remix

1. Copiar `KipuBank.sol` en Remix.  
2. Compilar con Solidity **0.8.20**.  
3. Desplegar ingresando `_withdrawalLimit` y `_bankCap` (por ejemplo, `1000000000000000000` y `10000000000000000000`).  
4. Usar `deposit()` (ingresando los wei en VALUE, más arriba) o enviar ETH al contrato para depositar.  
5. Usar `withdraw(amount)` (ingresando los wei en amount) para retirar ETH, respetando `WITHDRAWAL_LIMIT`.  
6. Consultar balances con `getBalance(address)` (ingresando la dirección correspondiente).  
7. Consultar estadísticas globales con `getVaultStats()`.  
8. Consultar estadísticas por usuario con `getUserStats(address)` (ingresando la dirección correspondiente).

---

## Conversión de Wei a Ether (machete)

| Ether | Wei |
|-------|-----|
| 0.01  | 10000000000000000 |
| 0.1   | 100000000000000000 |
| 0.5   | 500000000000000000 |
| 1     | 1000000000000000000 |

---

## Medidas de seguridad

- **NonReentrant modifier** para evitar ataques de reentrancy.  
- **Errores personalizados** para validar depósitos, retiros y límites.  
- **Checks-Effects-Interactions** en operaciones de ETH.  

---

Gracias por la paciencia de leer hasta aquí :-)
