# KipuBank - Contrato de Bóveda Personal en Ethereum

## Descripción del Proyecto

**KipuBank** es un contrato inteligente desarrollado en Solidity que funciona como bóveda. Permite a los usuarios depositar y retirar ETH de manera segura, 
con límites configurables y protección contra ataques de reentrancy.

### Características

- **Depósitos Seguros**: Los usuarios pueden depositar ETH en su cuenta personal dentro del contrato
- **Retiros Controlados**: Sistema de retiros con límites por transacción
- **Límite Global**: El banco tiene un tope máximo de depósitos
- **Protección Antireentrancy**: Para prevenir ataques de reentrada
- **Estadísticas Completas**: Tracking de operaciones por usuario y a nivel global
- **Optimización de Gas**: Variables inmutables y errores personalizados para menos costos


## Arquitectura del Contrato

### Variables Inmutables
- `WITHDRAWAL_LIMIT`: Límite máximo por retiro (definido en constructor)
- `BANK_CAP`: Capacidad total del banco (definido en constructor)

### Funcionalidades Principales

**Para Usuarios:**
- Depositar ETH mediante `deposit()` o envío directo de ETH 
- Retirar ETH mediante `withdraw(amount)`
- Consultar balance personal y estadísticas

**Información Disponible:**
- Balance individual de cada usuario
- Total de depósitos en el banco
- Estadísticas de operaciones (depósitos/retiros)

## Instrucciones de Deploy en Remix

### Paso 1: Preparar el Entorno

1. Acceda a Remix web en https://remix.ethereum.org
2. Cree un nuevo archivo llamado `KipuBank.sol`
3. Copie y pega el código del contrato

### Paso 2: Compilar el Contrato

1. Vaya a la pestaña del compilador de Solidity (ícono de S en el panel izquierdo)
2. Seleccione la versión del compilador: **0.8.20** (o superior)
3. Habilite "Auto compile" o haga clic en **"Compile KipuBank.sol"**
4. Verifique que no haya errores (debe aparecer una marca de verificación verde)

### Paso 3: Configurar Parámetros de Deploy

Antes de deploy, defina dos parámetros:

_withdrawalLimit: Límite máximo por retiro (en wei)
_bankCap: Capacidad total del banco (en wei)

**Ejemplo de valores:**
- **_withdrawalLimit**: `1000000000000000000` (1 ETH en wei)
- **_bankCap**: `10000000000000000000` (10 ETH en wei)

### Paso 4: Desplegar el Contrato

1. Vaya a la pestaña **"Deploy & run transactions"** (ícono de Ethereum)
2. Seleccione el entorno (**ENVIRONMENT**), por ejemplo **Remix VM (Prague)**
Y la wallet, por ej. MetaMask, para desplegar en testnet
3. En el campo **CONTRACT**, seleccione `KipuBank`
4. Haga clic en la flecha hacia abajo para expandir la sección naranja junto al botón **"Deploy"**
5. Ingrese los parámetros _withdrawalLimit y _bankCap:
1000000000000000000 y 10000000000000000000

6. Haga clic en **"transact"** o **"Deploy"** (si hace clic nuevamente en la flecha de la izquierda, como se detalla en el punto 4)
7. Confirme la transacción (si usa MetaMask)

### Paso 5: Verificar el deploy

Una vez hecho el deploy, el contrato aparecerá en **"Deployed Contracts"** y se podrá ver la dirección del contrato y las funciones para interactuar

## Cómo Interactuar con el Contrato

### 1. Depósito de ETH

**Opción A: Con la función `deposit()`**

1. En "Deployed Contracts", encuentre la función `deposit`
2. En el campo **VALUE** (arriba), ingrese la cantidad a depositar
3. Seleccione la unidad, por ej Wei
4. Haga clic en el botón `deposit`

**Opción B: Envío directo de ETH**

1. Copie la dirección del contrato desplegado
2. Envíe ETH a esa dirección desde su wallet
3. El contrato ejecutará automáticamente la función `receive()`

### 2. Consulta de balance

1. Expanda la función `getBalance` (botón azul)
2. Ingrese su dirección de wallet
3. Haga clic en `call`
4. El resultado mostrará su balance en wei

### 3. Retiro de ETH

1. Expanda la función `withdraw`
2. Ingrese el monto (**amount**) que desea retirar (en wei), por ejemplo 500000000000000000 (o sea 0.5 ETH)
3. Haga clic en el botón naranja `withdraw`
4. Se realizará la transferencia de ETH a su wallet

**Importante:** El retiro no superará el `WITHDRAWAL_LIMIT` definido en el deploy.

### 4. Estadísticas

**Estadísticas Globales:**
getBankStatistics() retorna:
- totalDeposits: Total de ETH en el banco
- depositCount: Número total de depósitos
- withdrawalCount: Número total de retiros

**Estadísticas de Usuario:**
getUserStatistics(address) retorna:
- balance: Balance del usuario
- deposits: Cantidad de depósitos realizados
- withdrawals: Cantidad de retiros realizados

### 5. Verificación si un Depósito está Permitido
isDepositAllowed(uint256 amount) retorna true/false
Con esta función se puede saber si un depósito supera el límite.

## Medidas de Seguridad

- **Patrón Checks-Effects-Interactions**: para prevenir vulnerabilidades
- **NonReentrant Modifier**: protección contra ataques de reentrada
- **Errores Personalizados**: mensajes claros y eficientes en gas
- **Validaciones Estrictas**: se verifican límites y balances
- **Variable Immutable**: Límites no modificables después del despliegue

## Conversiones Wei a Ether (machete útil)

Valor en Ether: Valor en Wei
0.01 ETH: 10000000000000000
0.1 ETH: 100000000000000000
0.5 ETH: 500000000000000000
1 ETH: 1000000000000000000
5 ETH: 5000000000000000000
10 ETH: 10000000000000000000

## Importante

1. **Testnet**: Siempre probar el contrato en redes de prueba (Sepolia, Goerli) 
2. **Gas**: Toda transacción (deposit/withdraw) consume gas
3. **Límites Inmutables**: Los límites establecidos en el constructor NO se modifican
4. **Parámetros**: Verificar que los valores sean correctos al desployar

## Tecnologías Utilizadas

- **Solidity**: ^0.8.20
- **Remix IDE**: Para desarrollo y despliegue
- **Patrones OpenZeppelin**: para seguridad contra reentrancy

## Autor

**Pilar**

## Licencia

MIT

## Soporte y Contacto

Si encuentra problemas durante el deploy o uso del contrato:
1. Verifique que Solidity sea la versión 0.8.20 o posterior
2. Asegúrese de tener suficiente ETH para gas
3. Revise los límites configurados en el constructor
4. Consulte los errores personalizados para diagnóstico

Gracias por la paciencia de leer hasta aquí :-)

**Fecha de última actualización**: Octubre 2025  
**Versión del Contrato**: 1.0
