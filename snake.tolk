const GAME_ID = 1;  // Меняй для нового контракта

contract Snake {
    storage: Storage
}

struct Storage {
    gameId: int32
    // Змейка: до 16 сегментов
    snakeX1: int32
    snakeY1: int32
    snakeX2: int32
    snakeY2: int32
    snakeX3: int32
    snakeY3: int32
    snakeX4: int32
    snakeY4: int32
    snakeX5: int32
    snakeY5: int32
    snakeX6: int32
    snakeY6: int32
    snakeX7: int32
    snakeY7: int32
    snakeX8: int32
    snakeY8: int32
    snakeLength: int32
    direction: int32  // 0=up, 1=right, 2=down, 3=left
    foodX: int32
    foodY: int32
    score: int32
    gameState: int32  // 0=playing, 1=win, 2=game over
}

fun Storage.load(): Storage {
    var ds = contract.getData().beginParse();
    if (ds.isEmpty()) {
        return Storage {
            gameId: GAME_ID,
            snakeX1: 3, snakeY1: 4,
            snakeX2: 3, snakeY2: 5,
            snakeX3: 3, snakeY3: 6,
            snakeX4: 0, snakeY4: 0,
            snakeX5: 0, snakeY5: 0,
            snakeX6: 0, snakeY6: 0,
            snakeX7: 0, snakeY7: 0,
            snakeX8: 0, snakeY8: 0,
            snakeLength: 3,
            direction: 0,
            foodX: 5,
            foodY: 2,
            score: 0,
            gameState: 0
        };
    }
    return Storage {
        gameId: ds.loadInt(32),
        snakeX1: ds.loadInt(32), snakeY1: ds.loadInt(32),
        snakeX2: ds.loadInt(32), snakeY2: ds.loadInt(32),
        snakeX3: ds.loadInt(32), snakeY3: ds.loadInt(32),
        snakeX4: ds.loadInt(32), snakeY4: ds.loadInt(32),
        snakeX5: ds.loadInt(32), snakeY5: ds.loadInt(32),
        snakeX6: ds.loadInt(32), snakeY6: ds.loadInt(32),
        snakeX7: ds.loadInt(32), snakeY7: ds.loadInt(32),
        snakeX8: ds.loadInt(32), snakeY8: ds.loadInt(32),
        snakeLength: ds.loadInt(32),
        direction: ds.loadInt(32),
        foodX: ds.loadInt(32),
        foodY: ds.loadInt(32),
        score: ds.loadInt(32),
        gameState: ds.loadInt(32)
    };
}

fun Storage.save(self) {
    contract.setData(
        beginCell()
        .storeInt(self.gameId, 32)
        .storeInt(self.snakeX1, 32).storeInt(self.snakeY1, 32)
        .storeInt(self.snakeX2, 32).storeInt(self.snakeY2, 32)
        .storeInt(self.snakeX3, 32).storeInt(self.snakeY3, 32)
        .storeInt(self.snakeX4, 32).storeInt(self.snakeY4, 32)
        .storeInt(self.snakeX5, 32).storeInt(self.snakeY5, 32)
        .storeInt(self.snakeX6, 32).storeInt(self.snakeY6, 32)
        .storeInt(self.snakeX7, 32).storeInt(self.snakeY7, 32)
        .storeInt(self.snakeX8, 32).storeInt(self.snakeY8, 32)
        .storeInt(self.snakeLength, 32)
        .storeInt(self.direction, 32)
        .storeInt(self.foodX, 32)
        .storeInt(self.foodY, 32)
        .storeInt(self.score, 32)
        .storeInt(self.gameState, 32)
        .endCell()
    );
}

fun isOnSnake(x: int, y: int, s: Storage): int {
    if (x == s.snakeX1 && y == s.snakeY1) { return 1; }
    if (x == s.snakeX2 && y == s.snakeY2) { return 1; }
    if (x == s.snakeX3 && y == s.snakeY3) { return 1; }
    if (s.snakeLength >= 4 && x == s.snakeX4 && y == s.snakeY4) { return 1; }
    if (s.snakeLength >= 5 && x == s.snakeX5 && y == s.snakeY5) { return 1; }
    if (s.snakeLength >= 6 && x == s.snakeX6 && y == s.snakeY6) { return 1; }
    if (s.snakeLength >= 7 && x == s.snakeX7 && y == s.snakeY7) { return 1; }
    if (s.snakeLength >= 8 && x == s.snakeX8 && y == s.snakeY8) { return 1; }
    return 0;
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
            
            // Смена направления (нельзя развернуться на 180)
            if (cmd == 119) { // 'w' - вверх
                if (storage.direction != 2) { storage.direction = 0; }
            } else if (cmd == 115) { // 's' - вниз
                if (storage.direction != 0) { storage.direction = 2; }
            } else if (cmd == 97) { // 'a' - влево
                if (storage.direction != 1) { storage.direction = 3; }
            } else if (cmd == 100) { // 'd' - вправо
                if (storage.direction != 3) { storage.direction = 1; }
            }
            
            // Двигаем змейку
            var newHeadX = storage.snakeX1;
            var newHeadY = storage.snakeY1;
            
            if (storage.direction == 0) { newHeadY -= 1; }
            if (storage.direction == 1) { newHeadX += 1; }
            if (storage.direction == 2) { newHeadY += 1; }
            if (storage.direction == 3) { newHeadX -= 1; }
            
            // Проверка столкновения со стеной
            if (newHeadX < 1 || newHeadX > 6 || newHeadY < 1 || newHeadY > 6) {
                storage.gameState = 2; // GAME OVER
            }
            
            // Проверка столкновения с собой
            if (isOnSnake(newHeadX, newHeadY, storage) == 1) {
                // Если это хвост, который уйдёт — не game over
                var tailX = storage.snakeX3;
                var tailY = storage.snakeY3;
                if (storage.snakeLength >= 4) { tailX = storage.snakeX4; tailY = storage.snakeY4; }
                if (storage.snakeLength >= 5) { tailX = storage.snakeX5; tailY = storage.snakeY5; }
                if (storage.snakeLength >= 6) { tailX = storage.snakeX6; tailY = storage.snakeY6; }
                if (storage.snakeLength >= 7) { tailX = storage.snakeX7; tailY = storage.snakeY7; }
                if (storage.snakeLength >= 8) { tailX = storage.snakeX8; tailY = storage.snakeY8; }
                
                if (newHeadX != tailX || newHeadY != tailY) {
                    storage.gameState = 2; // GAME OVER
                }
            }
            
            if (storage.gameState == 0) {
                // Двигаем все сегменты
                storage.snakeX8 = storage.snakeX7;
                storage.snakeY8 = storage.snakeY7;
                storage.snakeX7 = storage.snakeX6;
                storage.snakeY7 = storage.snakeY6;
                storage.snakeX6 = storage.snakeX5;
                storage.snakeY6 = storage.snakeY5;
                storage.snakeX5 = storage.snakeX4;
                storage.snakeY5 = storage.snakeY4;
                storage.snakeX4 = storage.snakeX3;
                storage.snakeY4 = storage.snakeY3;
                storage.snakeX3 = storage.snakeX2;
                storage.snakeY3 = storage.snakeY2;
                storage.snakeX2 = storage.snakeX1;
                storage.snakeY2 = storage.snakeY1;
                storage.snakeX1 = newHeadX;
                storage.snakeY1 = newHeadY;
                
                // Проверка: съела еду?
                if (newHeadX == storage.foodX && newHeadY == storage.foodY) {
                    storage.snakeLength += 1;
                    storage.score += 10;
                    
                    // Новая еда — фиксированная позиция для простоты
                    storage.foodX = 2 + (storage.score / 10) % 5;
                    storage.foodY = 2 + (storage.score / 10) % 5;
                    
                    // Если змейка выросла до 8 — победа
                    if (storage.snakeLength >= 8) {
                        storage.gameState = 1;
                    }
                }
            }
        }
    }
    
    storage.save();
    
    // Рендер карты 8x8
    var b = beginCell().storeUint(0, 32);
    
    if (storage.gameState == 1) {
        // "WIN! Score: XX"
        b = b.storeUint(87, 8); b = b.storeUint(73, 8); b = b.storeUint(78, 8);
        b = b.storeUint(33, 8); b = b.storeUint(32, 8);
        b = b.storeUint(83, 8); b = b.storeUint(99, 8); b = b.storeUint(111, 8);
        b = b.storeUint(114, 8); b = b.storeUint(101, 8); b = b.storeUint(58, 8);
        b = b.storeUint(32, 8);
        b = b.storeUint(48 + (storage.score / 10), 8);
        b = b.storeUint(48 + (storage.score % 10), 8);
    } else if (storage.gameState == 2) {
        // "GAME OVER!"
        b = b.storeUint(71, 8); b = b.storeUint(65, 8); b = b.storeUint(77, 8);
        b = b.storeUint(69, 8); b = b.storeUint(32, 8); b = b.storeUint(79, 8);
        b = b.storeUint(86, 8); b = b.storeUint(69, 8); b = b.storeUint(82, 8);
        b = b.storeUint(33, 8);
    } else {
        // Рендер карты
        var y = 0;
        // Строка 0
        b = b.storeUint(35, 8); b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8); b = b.storeUint(10, 8);
        
        // Строки 1-6
        var row = 1;
        while (row <= 6) {
            b = b.storeUint(35, 8);
            var col = 1;
            while (col <= 6) {
                if (storage.foodX == col && storage.foodY == row) {
                    b = b.storeUint(42, 8); // '*' - еда
                } else if (isOnSnake(col, row, storage) == 1) {
                    if (col == storage.snakeX1 && row == storage.snakeY1) {
                        b = b.storeUint(64, 8); // '@' - голова
                    } else {
                        b = b.storeUint(111, 8); // 'o' - тело
                    }
                } else {
                    b = b.storeUint(95, 8); // '_' - пол
                }
                col += 1;
            }
            b = b.storeUint(35, 8);
            b = b.storeUint(10, 8);
            row += 1;
        }
        
        // Строка 7
        b = b.storeUint(35, 8); b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        b = b.storeUint(35, 8); b = b.storeUint(35, 8);
        
        // Счёт
        b = b.storeUint(10, 8);
        b = b.storeUint(83, 8); b = b.storeUint(99, 8); b = b.storeUint(111, 8);
        b = b.storeUint(114, 8); b = b.storeUint(101, 8); b = b.storeUint(58, 8);
        b = b.storeUint(32, 8);
        b = b.storeUint(48 + (storage.score / 10), 8);
        b = b.storeUint(48 + (storage.score % 10), 8);
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
