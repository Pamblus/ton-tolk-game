const GAME_ID = 1;  // ЧИСЛО ДЛЯ НОВОГО КОНТРАКТА (2, 3, 9999...)

contract Testpoop {
    storage: Storage
}

struct Storage {
    gameId: int32
    playerX: int32
    playerY: int32
    enemyX: int32
    enemyY: int32
    enemyDirection: int32
    bulletX: int32
    bulletY: int32
    bulletExists: int32
    gameState: int32
}

fun Storage.load(): Storage {
    var ds = contract.getData().beginParse();
    if (ds.isEmpty()) {
        return Storage {
            gameId: GAME_ID,
            playerX: 4,
            playerY: 1,
            enemyX: 2,
            enemyY: 4,
            enemyDirection: 1,
            bulletX: 0,
            bulletY: 0,
            bulletExists: 0,
            gameState: 0
        };
    }
    return Storage {
        gameId: ds.loadInt(32),
        playerX: ds.loadInt(32),
        playerY: ds.loadInt(32),
        enemyX: ds.loadInt(32),
        enemyY: ds.loadInt(32),
        enemyDirection: ds.loadInt(32),
        bulletX: ds.loadInt(32),
        bulletY: ds.loadInt(32),
        bulletExists: ds.loadInt(32),
        gameState: ds.loadInt(32)
    };
}

fun Storage.save(self) {
    contract.setData(
        beginCell()
        .storeInt(self.gameId, 32)
        .storeInt(self.playerX, 32)
        .storeInt(self.playerY, 32)
        .storeInt(self.enemyX, 32)
        .storeInt(self.enemyY, 32)
        .storeInt(self.enemyDirection, 32)
        .storeInt(self.bulletX, 32)
        .storeInt(self.bulletY, 32)
        .storeInt(self.bulletExists, 32)
        .storeInt(self.gameState, 32)
        .endCell()
    );
}

fun onInternalMessage(in: InMessage) {
    var storage = Storage.load();
    
    if (storage.gameState != 0) {
        return;
    }
    
    if (!in.body.isEmpty()) {
        var commandSlice = in.body;
        
        var prefix = commandSlice.preloadUint(32);
        if (prefix == 0) {
            commandSlice.loadUint(32);
        }
        
        if (!commandSlice.isEndOfBits()) {
            var cmd = commandSlice.loadUint(8);
            
            // Движение игрока
            if (cmd == 119) { // 'w'
                if (storage.playerY > 1) {
                    storage.playerY -= 1;
                }
            } else if (cmd == 115) { // 's'
                if (storage.playerY < 6) {
                    storage.playerY += 1;
                }
            } else if (cmd == 97) { // 'a'
                if (storage.playerX > 1) {
                    storage.playerX -= 1;
                }
            } else if (cmd == 100) { // 'd'
                if (storage.playerX < 6) {
                    storage.playerX += 1;
                }
            } else if (cmd == 102) { // 'f' - выстрел
                if (storage.bulletExists == 0) {
                    storage.bulletExists = 1;
                    storage.bulletX = storage.playerX;
                    storage.bulletY = storage.playerY + 1;
                }
            }
            
            // Движение врага
            if (storage.enemyDirection == 1) {
                if (storage.enemyX < 6) {
                    storage.enemyX += 1;
                } else {
                    storage.enemyDirection = 0;
                    storage.enemyX -= 1;
                }
            } else {
                if (storage.enemyX > 1) {
                    storage.enemyX -= 1;
                } else {
                    storage.enemyDirection = 1;
                    storage.enemyX += 1;
                }
            }
            
            // Движение пули
            if (storage.bulletExists == 1) {
                storage.bulletY += 1;
                
                if (storage.bulletX == storage.enemyX && 
                    storage.bulletY == storage.enemyY) {
                    storage.bulletExists = 0;
                    storage.gameState = 1;
                }
                
                if (storage.bulletY > 7) {
                    storage.bulletExists = 0;
                }
            }
            
            // Встреча с врагом
            if (storage.playerX == storage.enemyX && 
                storage.playerY == storage.enemyY) {
                storage.gameState = 2;
            }
            
            // Достиг цели
            if (storage.playerX == 4 && storage.playerY == 6) {
                storage.gameState = 1;
            }
        }
    }
    
    storage.save();
    
    // Рендер карты
    var b = beginCell().storeUint(0, 32);
    
    if (storage.gameState == 1) {
        b = b.storeUint(87, 8);   // W
        b = b.storeUint(73, 8);   // I
        b = b.storeUint(78, 8);   // N
        b = b.storeUint(33, 8);   // !
        b = b.storeUint(32, 8);   // space
        b = b.storeUint(89, 8);   // Y
        b = b.storeUint(111, 8);  // o
        b = b.storeUint(117, 8);  // u
        b = b.storeUint(32, 8);   // space
        b = b.storeUint(119, 8);  // w
        b = b.storeUint(105, 8);  // i
        b = b.storeUint(110, 8);  // n
        b = b.storeUint(33, 8);   // !
        b = b.storeUint(32, 8);   // space
        b = b.storeUint(84, 8);   // T
        b = b.storeUint(104, 8);  // h
        b = b.storeUint(97, 8);   // a
        b = b.storeUint(110, 8);  // n
        b = b.storeUint(107, 8);  // k
        b = b.storeUint(115, 8);  // s
        b = b.storeUint(33, 8);   // !
    } else if (storage.gameState == 2) {
        b = b.storeUint(71, 8);   // G
        b = b.storeUint(65, 8);   // A
        b = b.storeUint(77, 8);   // M
        b = b.storeUint(69, 8);   // E
        b = b.storeUint(32, 8);   // space
        b = b.storeUint(79, 8);   // O
        b = b.storeUint(86, 8);   // V
        b = b.storeUint(69, 8);   // E
        b = b.storeUint(82, 8);   // R
        b = b.storeUint(33, 8);   // !
    } else {
        // Строка 0: ########
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(10, 8);
        
        // Строка 1: #___P___#
        b = b.storeUint(35, 8);
        if (storage.playerX == 1 && storage.playerY == 1) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 2 && storage.playerY == 1) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 3 && storage.playerY == 1) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 4 && storage.playerY == 1) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 5 && storage.playerY == 1) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 6 && storage.playerY == 1) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        b = b.storeUint(35, 8);
        b = b.storeUint(10, 8);
        
        // Строка 2: #______#
        b = b.storeUint(35, 8);
        if (storage.playerX == 1 && storage.playerY == 2) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 2 && storage.playerY == 2) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 3 && storage.playerY == 2) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 4 && storage.playerY == 2) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 5 && storage.playerY == 2) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 6 && storage.playerY == 2) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        b = b.storeUint(35, 8);
        b = b.storeUint(10, 8);
        
        // Строка 3: ###_####
        b = b.storeUint(35, 8); b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        if (storage.playerX == 4 && storage.playerY == 3) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        b = b.storeUint(35, 8); b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(10, 8);
        
        // Строка 4: #_E____#
        b = b.storeUint(35, 8);
        if (storage.playerX == 1 && storage.playerY == 4) { b = b.storeUint(80, 8); }
        else if (storage.enemyX == 1 && storage.enemyY == 4) { b = b.storeUint(69, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 2 && storage.playerY == 4) { b = b.storeUint(80, 8); }
        else if (storage.enemyX == 2 && storage.enemyY == 4) { b = b.storeUint(69, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 3 && storage.playerY == 4) { b = b.storeUint(80, 8); }
        else if (storage.enemyX == 3 && storage.enemyY == 4) { b = b.storeUint(69, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 4 && storage.playerY == 4) { b = b.storeUint(80, 8); }
        else if (storage.enemyX == 4 && storage.enemyY == 4) { b = b.storeUint(69, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 5 && storage.playerY == 4) { b = b.storeUint(80, 8); }
        else if (storage.enemyX == 5 && storage.enemyY == 4) { b = b.storeUint(69, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 6 && storage.playerY == 4) { b = b.storeUint(80, 8); }
        else if (storage.enemyX == 6 && storage.enemyY == 4) { b = b.storeUint(69, 8); }
        else { b = b.storeUint(95, 8); }
        b = b.storeUint(35, 8);
        b = b.storeUint(10, 8);
        
        // Строка 5: #______#
        b = b.storeUint(35, 8);
        if (storage.playerX == 1 && storage.playerY == 5) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 2 && storage.playerY == 5) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 3 && storage.playerY == 5) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 4 && storage.playerY == 5) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 5 && storage.playerY == 5) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 6 && storage.playerY == 5) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        b = b.storeUint(35, 8);
        b = b.storeUint(10, 8);
        
        // Строка 6: #___X___#
        b = b.storeUint(35, 8);
        if (storage.playerX == 1 && storage.playerY == 6) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 2 && storage.playerY == 6) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 3 && storage.playerY == 6) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 4 && storage.playerY == 6) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(88, 8); }
        if (storage.playerX == 5 && storage.playerY == 6) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        if (storage.playerX == 6 && storage.playerY == 6) { b = b.storeUint(80, 8); }
        else { b = b.storeUint(95, 8); }
        b = b.storeUint(35, 8);
        b = b.storeUint(10, 8);
        
        // Строка 7: ########
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
    }
    
    val reply = createMessage({
        bounce: BounceMode.NoBounce,
        dest: in.senderAddress,
        value: 0,
        body: b.endCell()
    });
    reply.send(SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE);
}

get fun get_state(): Storage {
    return Storage.load()
}
