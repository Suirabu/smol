pub const InstructionTag = enum(u8) {
    // Meta Operations
    nop     = 0x00,

    // Stack Operations
    push8   = 0x10,
    push16  = 0x11,
    drop    = 0x12,
    dup     = 0x13,
    swap    = 0x14,
    over    = 0x15,
    rot     = 0x16,
    store8  = 0x17,
    store16 = 0x18,
    load8   = 0x19,
    load16  = 0x1A,

    // Arithmetic Operations
    add     = 0x20,
    sub     = 0x21,
    mult    = 0x22,
    div     = 0x23,
    mod     = 0x24,

    // Bitwise Operations
    b_and   = 0x30,
    b_or    = 0x31,
    b_not   = 0x32,
    xor     = 0x33,
    shiftl  = 0x34,
    shiftr  = 0x35,

    // Comparison/Branching Operations
    cmp     = 0x40,
    jmp     = 0x41,
    jeq     = 0x42,
    jne     = 0x43,
    jlt     = 0x44,
    jle     = 0x45,
    jgt     = 0x46,
    jge     = 0x47,
    jsr     = 0x48,
    ret     = 0x49,
};

pub const Instruction = union(InstructionTag) {
    nop:     void,

    push8:   u8,
    push16:  u16,
    drop:    void,
    dup:     void,
    swap:    void,
    over:    void,
    rot:     void,
    store8:  void,
    store16: void,
    load8:   void,
    load16:  void,

    // Arithmetic Operations
    add:     void,
    sub:     void,
    mult:    void,
    div:     void,
    mod:     void,

    // Bitwise Operations
    b_and:   void,
    b_or:    void,
    b_not:   void,
    xor:     void,
    shiftl:  void,
    shiftr:  void,

    cmp:     void,
    jmp:     u16,
    jeq:     u16,
    jne:     u16,
    jlt:     u16,
    jle:     u16,
    jgt:     u16,
    jge:     u16,
    jsr:     u16,
    ret:     void,
};
