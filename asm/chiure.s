init:   ori x0, x0, 23
        ori x1, x0, 10
        ori x2, x0, 20
        ori x3, x0, 30
        ori x4, x0, 40
        ori x5, x0, 50
        ori x6, x0, 60
tag:    jal x7, func
        sw x0, x2, 0
        lw x0, x3, 0
        bne x2, x5, tag

func:   add x1, x1, x1
        add x1, x1, x1
        add x1, x1, x1
        add x2, x1, x1
        addi x1, x2, 23
        jalr x0, x7, 0

