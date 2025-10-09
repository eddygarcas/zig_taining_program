const std = @import("std");

export fn _start() noreturn {
    // Set up the stack pointer to 0x80000 (a typical early kernel stack)
    asm volatile (
        \\ mov rsp,0x80000
        \\ memory
    );

    callMain();
}

fn callMain() noreturn {
    main();
    unreachable;
}

pub fn main() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}