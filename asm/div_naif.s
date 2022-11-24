init:   ori x1, x0, 42
        ori x2, x0, 4
        or x3, x0, x2
        ori x5, x0, 1
        blt x2, x1, div
res:    sub x3, x3, x2
        addi x5, x5, -1
        sub x4, x1, x3
fin:    jal, x0, fin
div:    add x3, x3, x2
        addi x5, x5, 1
        blt x3, x1, div
        jal x30, res
