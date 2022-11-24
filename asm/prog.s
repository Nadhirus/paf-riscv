branch:ori x1, x0, 10
ori x2, x0, 10
add x3, x1, x2
sw x0, x3, 16
lw x4, x0, 16
blt x2, x3, branch
