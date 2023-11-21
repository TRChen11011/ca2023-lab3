#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>

extern uint64_t get_cycles();
extern uint64_t get_instret();

uint16_t CLZ_32(uint32_t x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);

    x -= ((x >> 1) & 0x55555555);
    x = ((x >> 2) & 0x33333333) + (x & 0x33333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);

    return (32 - (x & 0x3f));
}

uint64_t efficient_int_mul(uint32_t A, uint32_t B) {
	
    uint16_t n = CLZ_32(A);
    uint16_t m = CLZ_32(B);
    uint16_t result_bits;
    if(n>m) 
	    result_bits = n;
    else{
	    result_bits = m; 
	    uint32_t temp = A;
	    A = B;
	    B = temp;
	}
		
    uint64_t result = 0;

    for (int i = 0; i < 32-result_bits; i++) {
        if ((A >> i) & 1) {
            result += ((uint64_t)B << i);
        }
    }

    return result;
}

int main(void)
{
    /* measure cycles */
    uint64_t instret = get_instret();
    uint64_t oldcount = get_cycles();
    
    uint32_t A = 0x12345678; 
    uint32_t B = 0xffffdddd;

    uint64_t result = efficient_int_mul(A, B);
    
    uint64_t cyclecount = get_cycles() - oldcount;

    printf("cycle count: %u\n", (unsigned int) cyclecount);
    printf("instret: %x\n", (unsigned) (instret & 0xffffffff));
    printf("uint64: %"PRIX64"\n", result);

    return 0;
}