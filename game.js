class Game {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.gameState = 'overworld'; // overworld, combat, menu

        this.keys = {};
        this.lastTime = 0;

        this.tileSize = 32;
        this.mapWidth = 25;
        this.mapHeight = 19;

        this.setupEventListeners();
        this.initializeGame();

        requestAnimationFrame(this.gameLoop.bind(this));
    }

    setupEventListeners() {
        window.addEventListener('keydown', (e) => {
            this.keys[e.key] = true;
            e.preventDefault();
        });

        window.addEventListener('keyup', (e) => {
            this.keys[e.key] = false;
            e.preventDefault();
        });
    }

    initializeGame() {
        this.player = new Player(400, 300);
        this.world = new World();
        this.combat = new Combat();
        this.ui = new UI();

        this.enemies = [
            new Enemy(200, 200, 'Goon'),
            new Enemy(600, 400, 'Crow')
        ];
    }

    gameLoop(currentTime) {
        const deltaTime = currentTime - this.lastTime;
        this.lastTime = currentTime;

        this.update(deltaTime);
        this.render();

        requestAnimationFrame(this.gameLoop.bind(this));
    }

    update(deltaTime) {
        if (this.gameState === 'overworld') {
            this.player.update(deltaTime, this.keys);

            // Check for enemy encounters
            this.enemies.forEach(enemy => {
                if (this.checkCollision(this.player, enemy) && !enemy.defeated) {
                    this.gameState = 'combat';
                    this.combat.startBattle(this.player, enemy);
                }
            });
        } else if (this.gameState === 'combat') {
            this.combat.update(deltaTime, this.keys);

            if (this.combat.battleEnded) {
                this.gameState = 'overworld';
                if (this.combat.playerWon) {
                    this.combat.currentEnemy.defeated = true;
                    this.player.gainExp(this.combat.currentEnemy.expReward);
                }
                this.combat.reset();
            }
        }
    }

    render() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

        if (this.gameState === 'overworld') {
            this.world.render(this.ctx);
            this.player.render(this.ctx);

            this.enemies.forEach(enemy => {
                if (!enemy.defeated) {
                    enemy.render(this.ctx);
                }
            });
        } else if (this.gameState === 'combat') {
            this.combat.render(this.ctx);
        }

        this.ui.render(this.ctx, this.player, this.gameState);
    }

    checkCollision(rect1, rect2) {
        return rect1.x < rect2.x + rect2.width &&
               rect1.x + rect1.width > rect2.x &&
               rect1.y < rect2.y + rect2.height &&
               rect1.y + rect1.height > rect2.y;
    }
}

class Player {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.width = 24;
        this.height = 32;
        this.speed = 100;

        this.level = 1;
        this.hp = 20;
        this.maxHp = 20;
        this.attack = 5;
        this.defense = 2;
        this.exp = 0;
        this.expToNext = 100;

        this.direction = 'down';
    }

    update(deltaTime, keys) {
        const moveDistance = this.speed * (deltaTime / 1000);

        if (keys['ArrowUp'] || keys['w']) {
            this.y -= moveDistance;
            this.direction = 'up';
        }
        if (keys['ArrowDown'] || keys['s']) {
            this.y += moveDistance;
            this.direction = 'down';
        }
        if (keys['ArrowLeft'] || keys['a']) {
            this.x -= moveDistance;
            this.direction = 'left';
        }
        if (keys['ArrowRight'] || keys['d']) {
            this.x += moveDistance;
            this.direction = 'right';
        }

        // Keep player in bounds
        this.x = Math.max(0, Math.min(this.x, 800 - this.width));
        this.y = Math.max(0, Math.min(this.y, 600 - this.height));
    }

    render(ctx) {
        ctx.fillStyle = '#4A90E2';
        ctx.fillRect(this.x, this.y, this.width, this.height);

        // Simple direction indicator
        ctx.fillStyle = '#FFFFFF';
        switch(this.direction) {
            case 'up':
                ctx.fillRect(this.x + 8, this.y + 4, 8, 4);
                break;
            case 'down':
                ctx.fillRect(this.x + 8, this.y + 24, 8, 4);
                break;
            case 'left':
                ctx.fillRect(this.x + 4, this.y + 12, 4, 8);
                break;
            case 'right':
                ctx.fillRect(this.x + 16, this.y + 12, 4, 8);
                break;
        }
    }

    gainExp(amount) {
        this.exp += amount;

        while (this.exp >= this.expToNext) {
            this.levelUp();
        }

        this.updateUI();
    }

    levelUp() {
        this.exp -= this.expToNext;
        this.level++;

        const hpIncrease = Math.floor(Math.random() * 5) + 3;
        const attackIncrease = Math.floor(Math.random() * 3) + 1;
        const defenseIncrease = Math.floor(Math.random() * 2) + 1;

        this.maxHp += hpIncrease;
        this.hp = this.maxHp; // Full heal on level up
        this.attack += attackIncrease;
        this.defense += defenseIncrease;

        this.expToNext = Math.floor(this.expToNext * 1.5);
    }

    updateUI() {
        document.getElementById('playerHP').textContent = this.hp;
        document.getElementById('playerMaxHP').textContent = this.maxHp;
        document.getElementById('playerLevel').textContent = this.level;
        document.getElementById('playerExp').textContent = this.exp;
    }
}

class Enemy {
    constructor(x, y, name) {
        this.x = x;
        this.y = y;
        this.width = 24;
        this.height = 24;
        this.name = name;
        this.defeated = false;

        // Stats based on enemy type
        if (name === 'Goon') {
            this.hp = 8;
            this.maxHp = 8;
            this.attack = 3;
            this.defense = 1;
            this.expReward = 15;
        } else if (name === 'Crow') {
            this.hp = 12;
            this.maxHp = 12;
            this.attack = 4;
            this.defense = 2;
            this.expReward = 25;
        }
    }

    render(ctx) {
        if (this.name === 'Goon') {
            ctx.fillStyle = '#8B4513';
        } else if (this.name === 'Crow') {
            ctx.fillStyle = '#2F2F2F';
        }

        ctx.fillRect(this.x, this.y, this.width, this.height);

        // Simple enemy indicator
        ctx.fillStyle = '#FF0000';
        ctx.fillRect(this.x + 8, this.y + 8, 8, 8);
    }
}

class World {
    constructor() {
        this.generateMap();
    }

    generateMap() {
        // Simple grass background
    }

    render(ctx) {
        // Draw grass background
        ctx.fillStyle = '#228B22';
        ctx.fillRect(0, 0, 800, 600);

        // Draw some simple environmental details
        ctx.fillStyle = '#006400';
        for (let i = 0; i < 800; i += 64) {
            for (let j = 0; j < 600; j += 64) {
                if (Math.random() > 0.8) {
                    ctx.fillRect(i + 20, j + 20, 24, 24);
                }
            }
        }
    }
}

class Combat {
    constructor() {
        this.battleEnded = false;
        this.playerWon = false;
        this.currentEnemy = null;
        this.player = null;
        this.turn = 'player'; // player or enemy
        this.actionSelected = false;
        this.battleLog = [];
        this.waitTime = 0;
    }

    startBattle(player, enemy) {
        this.player = player;
        this.currentEnemy = enemy;
        this.battleEnded = false;
        this.playerWon = false;
        this.turn = 'player';
        this.actionSelected = false;
        this.battleLog = [`A wild ${enemy.name} appeared!`];
        this.waitTime = 1000;
    }

    update(deltaTime, keys) {
        if (this.waitTime > 0) {
            this.waitTime -= deltaTime;
            return;
        }

        if (this.turn === 'player' && !this.actionSelected) {
            if (keys[' ']) { // Spacebar to attack
                this.playerAttack();
                this.actionSelected = true;
                this.waitTime = 1000;
            }
        } else if (this.turn === 'enemy') {
            this.enemyAttack();
            this.waitTime = 1000;
        }

        // Check win/lose conditions
        if (this.currentEnemy.hp <= 0) {
            this.battleLog.push(`${this.currentEnemy.name} was defeated!`);
            this.battleLog.push(`You gained ${this.currentEnemy.expReward} EXP!`);
            this.playerWon = true;
            this.battleEnded = true;
        } else if (this.player.hp <= 0) {
            this.battleLog.push('You were defeated!');
            this.playerWon = false;
            this.battleEnded = true;
        }
    }

    playerAttack() {
        const damage = Math.max(1, this.player.attack - this.currentEnemy.defense + Math.floor(Math.random() * 3) - 1);
        this.currentEnemy.hp -= damage;
        this.battleLog.push(`You dealt ${damage} damage!`);

        this.turn = 'enemy';
        this.actionSelected = false;
    }

    enemyAttack() {
        const damage = Math.max(1, this.currentEnemy.attack - this.player.defense + Math.floor(Math.random() * 3) - 1);
        this.player.hp -= damage;
        this.player.updateUI();
        this.battleLog.push(`${this.currentEnemy.name} dealt ${damage} damage!`);

        this.turn = 'player';
    }

    render(ctx) {
        // Combat background
        ctx.fillStyle = '#4B0082';
        ctx.fillRect(0, 0, 800, 600);

        // Draw combatants
        ctx.fillStyle = '#4A90E2';
        ctx.fillRect(100, 400, 48, 64); // Player (larger in combat)

        if (this.currentEnemy.name === 'Goon') {
            ctx.fillStyle = '#8B4513';
        } else if (this.currentEnemy.name === 'Crow') {
            ctx.fillStyle = '#2F2F2F';
        }
        ctx.fillRect(600, 300, 48, 48); // Enemy (larger in combat)

        // Combat UI
        ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
        ctx.fillRect(50, 450, 700, 120);

        ctx.fillStyle = '#FFFFFF';
        ctx.font = '16px Courier New';

        // Enemy stats
        ctx.fillText(`${this.currentEnemy.name} HP: ${this.currentEnemy.hp}/${this.currentEnemy.maxHp}`, 450, 80);

        // Battle log
        for (let i = 0; i < this.battleLog.length && i < 4; i++) {
            ctx.fillText(this.battleLog[this.battleLog.length - 4 + i] || '', 70, 480 + i * 20);
        }

        // Controls
        if (this.turn === 'player' && !this.actionSelected && this.waitTime <= 0) {
            ctx.fillText('Press SPACE to attack', 70, 560);
        }
    }

    reset() {
        this.battleLog = [];
        this.waitTime = 0;
    }
}

class UI {
    render(ctx, player, gameState) {
        // UI is handled by HTML elements for this simple version
        player.updateUI();

        if (gameState === 'overworld') {
            ctx.fillStyle = '#FFFFFF';
            ctx.font = '14px Courier New';
            ctx.fillText('Use WASD or Arrow Keys to move', 10, 30);
            ctx.fillText('Walk into enemies to battle them!', 10, 50);
        }
    }
}

// Start the game
window.addEventListener('DOMContentLoaded', () => {
    new Game();
});