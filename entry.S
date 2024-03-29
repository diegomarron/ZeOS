/*
 * entry.S - Entry point to system mode from user mode
 */

#include <asm.h>
#include <segment.h>


ENOSYS = 38

/**************************************************/
/**** Save & Restore ******************************/
/**                                              **/
/** When we change to privilege level 0 (kernel) **/
/** (through an interrupt, a system call, an     **/
/** exception ...) we must save the state of the **/
/** currently running task (save).               **/
/**                                              **/
/** Stack layout in 'systemCall':                **/
/**                                              **/
/**   0(%esp) - %ebx    \                        **/
/**   4(%esp) - %ecx     |                       **/
/**   8(%esp) - %edx     |                       **/
/**   C(%esp) - %esi     | Register saved        **/
/**  10(%esp) - %edi     |  by 'save'            **/
/**  14(%esp) - %ebp     |                       **/
/**  18(%esp) - %eax     |                       **/
/**  1C(%esp) - %ds      |                       **/
/**  20(%esp) - %es      |                       **/
/**  24(%esp) - %fs      |                       **/
/**  28(%esp) - %gs     /                        **/
/**  2C(%esp) - %eip    \                        **/
/**  30(%esp) - %cs      |                       **/
/**  34(%esp) - %eflags  |  Return context saved **/
/**  38(%esp) - %oldesp  |   by the processor.   **/
/**  3C(%esp) - %oldss  /                        **/
/**                                              **/
/**************************************************/

#define SAVE_ALL\
      pushl %gs		;\
      pushl %fs		;\
      pushl %es		;\
      pushl %ds		;\
      pushl %eax	;\
      pushl %ebp	;\
      pushl %edi	;\
      pushl %esi	;\
      pushl %edx	;\
      pushl %ecx	;\
      pushl %ebx	;\
      movl $__KERNEL_DS, %edx	;\
      movl %edx, %ds	;\
      movl %edx, %es

#define RESTORE_ALL\
        popl %ebx	;\
        popl %ecx	;\
        popl %edx	;\
        popl %esi	;\
        popl %edi	;\
        popl %ebp	;\
        popl %eax	;\
        popl %ds	;\
        popl %es	;\
        popl %fs	;\
        popl %gs


	
#define EOI\
        movb $0x20,%al	;\
        outb %al, $0x20



/*
 EXCEPTIONS HANDLERS
	
 Some Exceptions need an extra addl to remove
 the error code.
 Only excep 8, 10-14 will need that.

*/


ENTRY(sys_excep_handler_division)
        SAVE_ALL
        call sys_excep_division
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_debug)
        SAVE_ALL
        call sys_excep_debug
        RESTORE_ALL
        iret
	
ENTRY(sys_excep_handler_nmi)
        SAVE_ALL
        call sys_excep_nmi
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_breakpoint)
        SAVE_ALL
        call sys_excep_breakpoint
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_overflow)
        SAVE_ALL
        call sys_excep_overflow
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_bound)
        SAVE_ALL
        call sys_excep_bound
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_opcode)
        SAVE_ALL
        call sys_excep_opcode
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_fpu)
        SAVE_ALL
        call sys_excep_fpu
        RESTORE_ALL
        iret


	
ENTRY(sys_excep_handler_double_fault)
        SAVE_ALL
        call sys_excep_double_fault
        RESTORE_ALL
	add $4, %esp     
        iret

	
ENTRY(sys_excep_handler_copr_overrun)
        SAVE_ALL
        call sys_excep_copr_overrun
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_invalid_tss)
        SAVE_ALL
        call sys_excep_invalid_tss
        RESTORE_ALL
	add $4, %esp      
        iret
	
ENTRY(sys_excep_handler_segement_not_present)
        SAVE_ALL
        call sys_excep_segement_not_present
        RESTORE_ALL
	add $4, %esp
        iret


ENTRY(sys_excep_handler_stack_fault)
        SAVE_ALL
        call sys_excep_stack_fault
        RESTORE_ALL
	add $4, %esp
        iret

ENTRY(sys_excep_handler_gen_protection)
        SAVE_ALL
        call sys_excep_gen_protection
        RESTORE_ALL
	add $4, %esp     
        iret


ENTRY(sys_excep_handler_page_fault)
        SAVE_ALL
        call sys_excep_page_fault
        RESTORE_ALL
	add $4, %esp      
        iret

ENTRY(sys_excep_handler_excep15)
        SAVE_ALL
        call sys_excep_excep15
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_math)
        SAVE_ALL
        call sys_excep_math
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_align_check)
        SAVE_ALL
        call sys_excep_align_check
        RESTORE_ALL
	add $4, %esp      
        iret

ENTRY(sys_excep_handler_machine)
        SAVE_ALL
        call sys_excep_machine
        RESTORE_ALL
        iret

ENTRY(sys_excep_handler_simd)
        SAVE_ALL
        call sys_excep_simd
        RESTORE_ALL
        iret
	

/*
  H/W Interrupts
 IDT entries from 32-255 are reserved for h/w and soft interrupts
  The main difference compared with excep handling is the need to
  indicate an EOI (End Of Int)
*/
	
	
ENTRY(clock_handler)
        SAVE_ALL
        call clock_routine
        EOI
        RESTORE_ALL
        iret

ENTRY(kbd_handler)
        SAVE_ALL
        call kbd_routine
        EOI
        RESTORE_ALL
        iret
		



/*
 SYSTEM CALL INTERRUPT
 we are setting int 80, same as linux for system calls
*/

#define nr_syscalls ((syscall_table_size)/4)


ENTRY(syscall_handler)
        SAVE_ALL
	cmpl $(nr_syscalls),%eax
        jae err_no_syscall
        call *sys_call_table(,%eax,0x04)
        movl %eax,24(%esp)
        RESTORE_ALL
        iret
	
err_no_syscall:
	movl $-ENOSYS,24(%esp)
	RESTORE_ALL
	iret

		
ENTRY(sys_call_table)
	.long sys_ni_syscall   // 0
	.long sys_exit
	.long sys_fork
	.long sys_ni_syscall	
	.long sys_write
	.long sys_ni_syscall	// 5
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall  	// 10 
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall  	// 15 
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_getpid     	// 20
	.long sys_sem_init
        .long sys_sem_wait
	.long sys_sem_signal
	.long sys_sem_destroy   
	.long sys_ni_syscall  	// 25 
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall  	// 30 
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_nice
	.long sys_get_stats 	// 35 
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall  	// 40 
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall
	.long sys_ni_syscall  	// 45 
	


	
syscall_table_size=(.-sys_call_table)



	
	

	
	
