#include "base-isa.rules"

#ruledef {
    error_halt => asm {
        out r0, 1
        hlt
    }
}
jump test_zero_flag_on

fail:
    error_halt

test_zero_flag_on:
    mov   r0, 0
    test  r0, -1

    jump_not_zero          fail
    jump_zero              test_zero_flag_off
    error_halt

test_zero_flag_off:
    mov   r0, 1
    test  r0, -1

    jump_zero              fail
    jump_not_zero          test_negative_flag_on
    error_halt

test_negative_flag_on:
    mov   r0, -1
    test  r0, -1

    jump_not_negative      fail
    jump_negative          test_negative_flag_off
    error_halt

test_negative_flag_off:
    mov   r0, 0
    test  r0, -1

    jump_negative          fail
    jump_not_negative      test_carry_flag_off
    error_halt


test_carry_flag_off:
    mov   r0, 15
    add   r0, 15

    jump_carry             fail
    jump_not_carry         test_carry_flag_on
    error_halt

test_carry_flag_on:
    mov   r0, -1
    add   r0, 15

    jump_not_carry         fail
    jump_carry             test_borrow_flag_off
    error_halt

test_borrow_flag_off:
    mov   r0, 1
    comp  r0, 1

    jump_carry             fail
    jump_not_carry         test_borrow_flag_on
    error_halt

test_borrow_flag_on:
    mov   r0, 0
    comp  r0, 1

    jump_not_carry         fail
    jump_carry             test_overflow_flag_off
    error_halt

test_overflow_flag_off:
    mov   r0, 0
    slo   r0, 31
    slo   r0, 31
    slo   r0, 31
    sub   r0, 1

    jump_overflow          fail
    jump_not_overflow      test_overflow_flag_on
    error_halt

test_overflow_flag_on:
    mov   r0, 0
    slo   r0, 31
    slo   r0, 31
    slo   r0, 31
    add   r0, 1

    jump_not_overflow      fail
    jump_overflow          test_equal
    error_halt

test_equal:
    comp  r0, r0

    jump_not_equal         fail
    jump_below             fail
    jump_above             fail
    jump_less              fail
    jump_greater           fail

    jump_equal             .success_1
    error_halt
  .success_1:
    jump_below_or_equal    .success_2
    error_halt
  .success_2:
    jump_above_or_equal    .success_3
    error_halt
  .success_3:
    jump_less_or_equal     .success_4
    error_halt
  .success_4:
    jump_greater_or_equal  test_not_equal
    error_halt

test_not_equal:
    mov   r0, 0
    comp  r0, 1

    jump_equal             fail

    jump_not_equal         .success_1
    error_halt
  .success_1:
    jump_below             .success_2    ; Exactly one of these two should trigger
    jump_above             .success_2
    error_halt
  .success_2:
    jump_less              test_ucomp_1  ; Exactly one of these two should trigger
    jump_greater           test_ucomp_1
    error_halt

test_ucomp_1:
    mov   r0, 10
    comp  r0, 5
    jump_below             fail
    jump_below_or_equal    fail
    jump_above             .success
    error_halt
  .success:
    jump_above_or_equal    test_ucomp_2
    error_halt

test_ucomp_2:
    mov   r0, 5
    comp  r0, 10
    jump_above             fail
    jump_above_or_equal    fail
    jump_below             .success
    error_halt
  .success:
    jump_below_or_equal    test_ucomp_3
    error_halt

fail2:
    error_halt

test_ucomp_3:
    mov   r0, -10
    comp  r0, 5
    jump_below             fail2
    jump_below_or_equal    fail2
    jump_above             .success
    error_halt
  .success:
    jump_above_or_equal    test_ucomp_4
    error_halt
    
test_ucomp_4:
    mov   r0, 5
    comp  r0, -10
    jump_above fail2
    jump_above_or_equal    fail2
    jump_below             .success
    error_halt
  .success:
    jump_below_or_equal    test_scomp_1
    error_halt


test_scomp_1:
    mov   r0, 10
    comp  r0, 5
    jump_less              fail2
    jump_less_or_equal     fail2
    jump_greater           .success
    error_halt
  .success:
    jump_greater_or_equal  test_scomp_2
    error_halt

test_scomp_2:
    mov   r0, 5
    comp  r0, 10
    jump_greater           fail2
    jump_greater_or_equal  fail2
    jump_less              .success
    error_halt
  .success:
    jump_less_or_equal     test_scomp_3
    error_halt

test_scomp_3:
    mov   r0, 5
    comp  r0, -10
    jump_less              fail2
    jump_less_or_equal     fail2
    jump_greater           .success
    error_halt
  .success:
    jump_greater_or_equal  test_scomp_4
    error_halt
    
test_scomp_4:
    mov   r0, -10
    comp  r0, 5
    jump_greater           fail2
    jump_greater_or_equal  fail2
    jump_less              .success
    error_halt
  .success:
    jump_less_or_equal     done
    error_halt

done:
    hlt

