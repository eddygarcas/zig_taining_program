ENTRY(_start)

MEMORY
{
    RAM(rwx):ORIGIN =  0x100000,LENGTH = 1M
}

SECTIONS
{
    .=ORIGIN(RAM);
    .text : {
        *(.text._start)
        *(.text*)
    }
    .rodata : {*(.rodata*)}
    .data : {*(.data*)}
    .bss : {*(.bss*)}
}
