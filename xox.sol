pragma solidity ^0.4.15;
contract XOX {
    
    uint constant STATE_CREATED = 0;
    uint constant STATE_PLAYER1_MOVE = 1;
    uint constant STATE_PLAYER2_MOVE = 2;
    uint constant STATE_PLAYER1_WIN = 3;
    uint constant STATE_PLAYER2_WIN = 4;
    uint constant STATE_PLAYERS_DRAW = 5;
    
    struct Game {
        uint state;
        address player1;
        address player2;
        byte[3][3] field;
    }
    
    mapping(address => uint) player1Games;
    mapping(address => uint) player2Games;
    
    mapping(uint => Game) games;
    
    uint gameCount;
    
    event ErrorIncorrectArgs(string name, uint value);
    event ErrorIncorrectActionState(string info, uint state);
    event ErrorCellOccupied(byte[3][3] field, uint x, uint y);
    event ErrorAlreadyExists (uint gameId);
    
    event GameFinished (byte[3][3] field, byte winner);
    event Move (byte player, uint x, uint y, byte[3][3] field);
    
    event Trace(string s, uint gameId);
    
    function XOX() public {
        gameCount = 1;
    }
    
    function joinGame() public returns(bool) {
        uint gameId;
        byte playerNum;
        (gameId, playerNum) = getGameId(msg.sender);
        
        Trace('Get game id', gameId);
        
        // player already joined game
        if (gameId > 0) {
            revert();
            ErrorAlreadyExists(gameId);
            return false;
        } else {
            gameId = gameCount;
        }
        
        if (games[gameId].player1 == address(0x0)) {
            games[gameId].player1 = msg.sender;
            player1Games[msg.sender] = gameId;
            
            Trace('player 1 assigned', gameId);
        } else if (games[gameCount].player2 == address(0x0)) {
            games[gameId].player2 = msg.sender;
            games[gameId].state = STATE_PLAYER1_MOVE;
            
            player2Games[msg.sender] = gameId;
            Trace('player 2 assigned', gameId);
            ++gameCount;
        }
        
        return true;
    }
    
    function move(uint x, uint y) public returns(bool, byte){
        if (x > 2) {
            ErrorIncorrectArgs('x', x);
        }
        
        if (y > 2) {
            ErrorIncorrectArgs('y', y);
        }        
        
        uint gameId;
        byte playerNum;
        (gameId, playerNum) = getGameId(msg.sender);
        
        Game memory game = games[gameId];
        
        // if correct ability to move
        if ((game.state == STATE_PLAYER1_MOVE && playerNum == "X") || 
            (game.state == STATE_PLAYER2_MOVE && playerNum == "O")) {
            if (game.field[x][y] == 0) {
                game.field[x][y] = playerNum;
                
                Move(playerNum, x, y, game.field);
                
                bool finished;
                byte player;
                (finished, player) = checkGame(game);
                
                if (finished) {
                    if (player == "X") {
                        game.state = STATE_PLAYER1_WIN;
                    } else if (player == "O") {
                        game.state = STATE_PLAYER2_WIN;
                    } else if (player == 0) {
                        game.state = STATE_PLAYERS_DRAW;
                    }
                    GameFinished(game.field, player);
                } else {
                    if (game.state == STATE_PLAYER1_MOVE) { 
                        game.state = STATE_PLAYER2_MOVE; }
                    else if (game.state == STATE_PLAYER2_MOVE) { 
                        game.state = STATE_PLAYER1_MOVE;
                    }
                }
                
                // saving game
                games[gameId] = game;
                
                return (finished, player);
                
            } else {
                ErrorCellOccupied(game.field, x, y);
                
                return (false, 0);
            }
        } else {
            ErrorIncorrectActionState('move', game.state);
            return (false, 0);
        }
        
        return (false, 0);
    }
    
    function deleteGame() public returns(bool) {
        uint gameId;
        byte playerNum;
        (gameId, playerNum) = getGameId(msg.sender);
        
        if (gameId >0) {
            delete player1Games[msg.sender];
            delete player2Games[msg.sender];
            delete games[gameId];
            
            Trace("Deleted ", gameId);
        }
        return true;
    }
    
    function getGameId(address _player) private view returns(uint, byte) {
        byte playerNum = 0;
        uint gameId = 0;
        
        if (player1Games[_player] > 0) {
            playerNum = "X";
            gameId = player1Games[_player];
        }
        
        if (player2Games[_player] > 0) {
            playerNum = "O";
            gameId = player2Games[_player];
        }
        
        return (gameId, playerNum);
    }
    
    // (finished, winner)
    function checkGame(Game game) private pure returns(bool, byte) {
        uint size = 3;

        byte charColumn = 0;
        byte charRow = 0;
        byte charDiag1 = 0;
        byte charDiag2 = 0;
        
        bool resultColumn;
        bool resultRow;
        bool resultDiag1 = true;
        bool resultDiag2 = true;
        bool filled = true; 
    
        for(uint i = 0; i < size; i++) {
            if (charDiag1 == 0) charDiag1 = game.field[i][i];
            if (charDiag2 == 0) charDiag2 = game.field[size - i - 1][i];
            
            if (charDiag1 != game.field[i][i] || game.field[i][i] == 0) {
                resultDiag1 = false;
            }
            
            if (charDiag2 != game.field[size - i - 1][i] || game.field[size - i - 1][i] == 0) {
                resultDiag2 = false;
            }
            
            charColumn = byte(0);
            charRow = byte(0);
            resultColumn = true;
            resultRow = true;
            for (uint j = 0; j < size; j++) {
                if (game.field[i][j] == 0) {
                    filled = false;
                }
                
                if (charColumn == 0) { 
                    charColumn = game.field[i][j];
                }
                if (charRow == 0) {
                    charRow = game.field[j][i];
                }
                
                if (charColumn != game.field[i][j] || game.field[i][j] == 0) {
                    resultColumn = false;
                }
                
                if (charRow != game.field[j][i] || game.field[j][i] == 0) {
                    resultRow = false;
                }
            }
            
            if (resultColumn == true || resultRow == true) {
                break;
            }
        }
        
        if (resultDiag1) {
            return (resultDiag1, charDiag1);
        } else if (resultDiag2) {
            return (resultDiag2, charDiag2);
        }else if (resultColumn) {
            return (resultColumn, charColumn);
        } else if (resultRow) {
            return (resultRow, charRow);
        } else if (filled) {
            return (filled, 0);
        }
        
        return (false, 0);
    }
}
