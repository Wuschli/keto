const c = @import("./chunk.zig");
const Line = c.Line;
const std = @import("std");
const fmt = std.fmt;

pub const Token = struct {
    const Self = @This();
    type: TokenType,
    start: []const u8,
    line: Line,
};

pub const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,
    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,
    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,
    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FOR,
    FUN,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    ERROR,
    EOF,
};

pub const Scanner = struct {
    const Self = @This();
    start: []const u8,
    current: []const u8,
    line: Line,

    pub fn init(source: []const u8) !Self {
        return Self{
            .start = source,
            .current = source,
            .line = 1,
        };
    }

    pub fn scanToken(self: *Self) Token {
        self.skipWhitespace();
        self.start = self.current;

        if (self.isAtEnd())
            return self.makeToken(.EOF);

        const char = self.advance();

        if (isAlpha(char)) return self.identifier();
        if (isDigit(char)) return self.number();

        switch (char) {
            '(' => return self.makeToken(.LEFT_PAREN),
            ')' => return self.makeToken(.RIGHT_PAREN),
            '{' => return self.makeToken(.LEFT_BRACE),
            '}' => return self.makeToken(.RIGHT_BRACE),
            ';' => return self.makeToken(.SEMICOLON),
            ',' => return self.makeToken(.COMMA),
            '.' => return self.makeToken(.DOT),
            '-' => return self.makeToken(.MINUS),
            '+' => return self.makeToken(.PLUS),
            '/' => return self.makeToken(.SLASH),
            '*' => return self.makeToken(.STAR),
            '!' => {
                if (self.match('=')) {
                    return self.makeToken(.BANG_EQUAL);
                } else {
                    return self.makeToken(.BANG);
                }
            },
            '=' => {
                if (self.match('=')) {
                    return self.makeToken(.EQUAL_EQUAL);
                } else {
                    return self.makeToken(.EQUAL);
                }
            },
            '<' => {
                if (self.match('=')) {
                    return self.makeToken(.LESS_EQUAL);
                } else {
                    return self.makeToken(.LESS);
                }
            },
            '>' => {
                if (self.match('=')) {
                    return self.makeToken(.GREATER_EQUAL);
                } else {
                    return self.makeToken(.GREATER);
                }
            },
            '"' => return self.string(),

            else => return self.makeErrorToken("Unexpected character."),
        }

        return self.makeErrorToken("Unexpected character.");
    }

    fn makeToken(self: *Self, tokenType: TokenType) Token {
        const length = @ptrToInt(self.current.ptr) - @ptrToInt(self.start.ptr);
        return Token{
            .type = tokenType,
            .start = self.start[0..length],
            .line = self.line,
        };
    }

    fn makeErrorToken(self: *Self, message: []const u8) Token {
        return Token{
            .type = .ERROR,
            .start = message,
            .line = self.line,
        };
    }

    fn isAtEnd(self: *Self) bool {
        return self.current.len <= 0 or self.current[0] == 0;
    }

    fn advance(self: *Self) u8 {
        const result = self.current[0];
        self.current.ptr += 1;
        self.current.len -= 1;
        return result;
    }

    fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd())
            return false;
        if (self.current[0] != expected) return false;
        _ = self.advance();
        return true;
    }

    fn peek(self: *Self) u8 {
        if (self.isAtEnd())
            return 0;
        return self.current[0];
    }

    fn peekNext(self: *Self) u8 {
        if (self.isAtEnd() or self.current.len < 2)
            return 0;
        return self.current[1];
    }

    fn skipWhitespace(self: *Self) void {
        while (self.current.len > 0) {
            const char = self.peek();
            switch (char) {
                0xAA, ' ', '\r', '\t' => _ = self.advance(),
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd()) {
                            _ = self.advance();
                        }
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    fn checkKeyword(self: *Self, start: usize, length: usize, rest: []const u8, tokenType: TokenType) TokenType {
        if (@ptrToInt(self.current.ptr) - @ptrToInt(self.start.ptr) != start + length) // compare length
            return .IDENTIFIER;

        const source = self.start[start .. start + length];
        if (std.mem.eql(u8, source, rest)) // compare strings
            return tokenType;

        return .IDENTIFIER;
    }

    fn identifierType(self: *Self) TokenType {
        switch (self.start[0]) {
            'a' => return self.checkKeyword(1, 2, "nd", .AND),
            'c' => return self.checkKeyword(1, 4, "lass", .CLASS),
            'e' => return self.checkKeyword(1, 3, "lse", .ELSE),
            'f' => {
                if (@ptrToInt(self.current.ptr) - @ptrToInt(self.start.ptr) > 1) {
                    switch (self.start[1]) {
                        'a' => return self.checkKeyword(2, 3, "lse", .FALSE),
                        'o' => return self.checkKeyword(2, 1, "r", .FOR),
                        'u' => return self.checkKeyword(2, 1, "n", .FUN),
                        else => return .IDENTIFIER,
                    }
                }
            },
            'i' => return self.checkKeyword(1, 1, "f", .IF),
            'n' => return self.checkKeyword(1, 2, "il", .NIL),
            'o' => return self.checkKeyword(1, 1, "r", .OR),
            'p' => return self.checkKeyword(1, 4, "rint", .PRINT),
            'r' => return self.checkKeyword(1, 5, "eturn", .RETURN),
            's' => return self.checkKeyword(1, 4, "uper", .SUPER),
            't' => {
                if (@ptrToInt(self.current.ptr) - @ptrToInt(self.start.ptr) > 1) {
                    switch (self.start[1]) {
                        'h' => return self.checkKeyword(2, 2, "is", .THIS),
                        'r' => return self.checkKeyword(2, 2, "ue", .TRUE),
                        else => return .IDENTIFIER,
                    }
                }
            },
            'v' => return self.checkKeyword(1, 2, "ar", .VAR),
            'w' => return self.checkKeyword(1, 4, "hile", .WHILE),

            else => return .IDENTIFIER,
        }

        return .IDENTIFIER;
    }

    fn identifier(self: *Self) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) _ = self.advance();
        return self.makeToken(self.identifierType());
    }

    fn string(self: *Self) Token {
        while (self.peek() != '"') {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }
        if (self.isAtEnd()) return self.makeErrorToken("Unterminated string.");
        _ = self.advance();
        return self.makeToken(.STRING);
    }

    fn number(self: *Self) Token {
        while (isDigit(self.peek())) _ = self.advance();
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) _ = self.advance();
        }
        return self.makeToken(.NUMBER);
    }
};

fn isAlpha(char: u8) bool {
    return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_';
}

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}
