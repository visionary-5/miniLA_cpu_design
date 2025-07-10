.text
_start:
    # --------------------
    # 阶段0：等待SW[1:0]=1，实时显示计时器值
    # --------------------
    lu12i.w $a7, -1              # 初始化外设基地址高位为0xFFFFF000
    ori     $a7, $a7, 0x000      # 完整基地址 $a7 = 0xFFFFF000

phase0:
    ld.w    $a0, $a7, 0x20       # 读取计时器值到$a0
    st.w    $a0, $a7, 0x00       # 将计时器值显示在数码管

    ld.w    $a1, $a7, 0x70       # 读取拨码开关值
    andi    $a1, $a1, 0x3        # 保留最低2位
    ori     $t0, $zero, 0x1      # 设置比较值1
    bne     $a1, $t0, phase0     # 如果SW[1:0]!=1，继续等待

    # --------------------
    # 阶段1：设置随机数种子为当前计时器值
    # --------------------
    ld.w    $a0, $a7, 0x20       # 再次读取计时器值作为种子
    or      $s1, $a0, $zero      # 保存种子值到$s1
    st.w    $s1, $a7, 0x00       # 显示种子值

phase1:
    ld.w    $a1, $a7, 0x70       # 读取拨码开关状态
    andi    $a1, $a1, 0x3
    ori     $t0, $zero, 0x2      # 设置比较值2
    bne     $a1, $t0, phase1     # 如果SW[1:0]!=2，继续等待

    # --------------------
    # 阶段2：使用LFSR生成8个4bit随机数，存入数组并显示
    # --------------------
    ori     $s2, $zero, 0x100    # 设置数组基地址为0x100

phase2_loop:
    # --- LFSR 反馈计算 ---
    andi    $t1, $s1, 1
    srli.w  $t2, $s1, 1
    andi    $t2, $t2, 1
    srli.w  $t3, $s1, 21
    andi    $t3, $t3, 1
    srli.w  $t4, $s1, 31
    andi    $t4, $t4, 1

    xor     $t5, $t1, $t2
    xor     $t5, $t5, $t3
    xor     $t5, $t5, $t4        # t5为反馈位

    slli.w  $s1, $s1, 1
    or      $s1, $s1, $t5        # 左移后补入反馈位

    # --- 提取8个4bit数并存入数组 ---
    or      $a2, $s1, $zero      # 临时副本
    ori     $s3, $zero, 0x0      # index初始化
    ori     $s4, $zero, 0x0      # 显示值初始化

extract_loop:
    andi    $t6, $a2, 0xF        # 提取低4位
    slli.w  $t7, $s3, 2
    add.w   $a3, $s2, $t7
    st.w    $t6, $a3, 0x0        # 写入内存数组

    # 构建显示值
    slli.w  $t8, $s3, 2
    sll.w   $t6, $t6, $t8
    or      $s4, $s4, $t6

    srli.w  $a2, $a2, 4
    addi.w  $s3, $s3, 1
    ori     $t8, $zero, 8
    bne     $s3, $t8, extract_loop

    st.w    $s4, $a7, 0x0        # 显示组合值

    # --- 等待SW[1:0]==3 ---
    ld.w    $a1, $a7, 0x70
    andi    $a1, $a1, 0x3
    ori     $t0, $zero, 0x3
    bne     $a1, $t0, phase2_loop

    # --------------------
    # 阶段3：对随机数组进行冒泡排序
    # --------------------
    ori     $s5, $zero, 0x0      # i = 0
outer_loop:
    ori     $s6, $zero, 0x0      # j = 0
    ori     $s7, $zero, 0x1c     # s7 = 28 (7*4)
    sub.w   $s7, $s7, $s5        # s7 = 7 - i

inner_loop:
    add.w   $a4, $s2, $s6
    ld.w    $t1, $a4, 0x0        # t1 = arr[j]
    addi.w  $s8, $s6, 4
    add.w   $a4, $s2, $s8
    ld.w    $t2, $a4, 0x0        # t2 = arr[j+1]

    sub.w   $t3, $t2, $t1
    srli.w  $t3, $t3, 31         # t2 < t1 ?
    beq     $t3, $zero, no_swap
    # 交换 arr[j] 和 arr[j+1]
    add.w   $a4, $s2, $s6
    st.w    $t2, $a4, 0x0
    add.w   $a4, $s2, $s8
    st.w    $t1, $a4, 0x0

no_swap:
    addi.w  $s6, $s6, 4
    sub.w   $t3, $s6, $s7
    srli.w  $t3, $t3, 31
    bne     $t3, $zero, inner_loop

    addi.w  $s5, $s5, 4
    ori     $a4, $zero, 0x1c
    sub.w   $t3, $s5, $a4
    srli.w  $t3, $t3, 31
    bne     $t3, $zero, outer_loop

    # 排序完成后点亮LED0
    ori     $t1, $zero, 0x1
    st.w    $t1, $a7, 0x60

phase3:
    ld.w    $a1, $a7, 0x70
    andi    $a1, $a1, 0x3
    bne     $a1, $r0, phase3     # 等待SW[1:0]==0

    # --------------------
    # 阶段4：显示排序后的数组
    # --------------------
    ori     $s4, $zero, 0x0      # 显示值清零
    ori     $s3, $zero, 0x0      # s3为偏移量

display_loop:
    add.w   $a3, $s2, $s3
    ld.w    $t0, $a3, 0x0
    sll.w   $t0, $t0, $s3        # 左移到位
    or      $s4, $s4, $t0

    addi.w  $s3, $s3, 4
    ori     $a3, $zero, 0x20
    sub.w   $t5, $s3, $a3
    srli.w  $t5, $t5, 31
    bne     $t5, $zero, display_loop

    st.w    $s4, $a7, 0x0        # 显示排序结果

    # 程序结束：死循环等待
end:
    b       end
