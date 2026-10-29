//! box_rust_dsp: small no_std functions with a C ABI, called from an Arduino sketch.
//! The sketch sees them through `box_rust_dsp.h`; nothing here allocates or panics on valid input.
#![cfg_attr(not(test), no_std)]

use core::panic::PanicInfo;
use core::slice;

/// CRC-32 (IEEE 802.3, reflected, init/xorout 0xFFFFFFFF) of `len` bytes at `data`.
///
/// # Safety
/// `data` must point to `len` readable bytes (or be null with `len == 0`).
#[no_mangle]
pub unsafe extern "C" fn rust_crc32(data: *const u8, len: usize) -> u32 {
    if data.is_null() || len == 0 {
        return 0;
    }
    let bytes = unsafe { slice::from_raw_parts(data, len) };
    let mut crc = 0xFFFF_FFFFu32;
    for &b in bytes {
        crc ^= b as u32;
        for _ in 0..8 {
            crc = if crc & 1 != 0 { (crc >> 1) ^ 0xEDB8_8320 } else { crc >> 1 };
        }
    }
    !crc
}

/// Exponential moving average in Q16.16 fixed point: `avg + (sample - avg) * alpha`,
/// with `alpha_q16` in 0..=65536. Saturates instead of overflowing.
#[no_mangle]
pub extern "C" fn rust_ema_q16(avg: i32, sample: i32, alpha_q16: u32) -> i32 {
    let alpha = alpha_q16.min(65536) as i64;
    let delta = sample as i64 - avg as i64;
    let next = avg as i64 + ((delta * alpha) >> 16);
    next.clamp(i32::MIN as i64, i32::MAX as i64) as i32
}

#[cfg(not(test))]
#[panic_handler]
fn panic(_: &PanicInfo) -> ! {
    loop {}
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn crc32_check_value() {
        let data = b"123456789";
        assert_eq!(unsafe { rust_crc32(data.as_ptr(), data.len()) }, 0xCBF4_3926);
        assert_eq!(unsafe { rust_crc32(core::ptr::null(), 0) }, 0);
    }

    #[test]
    fn ema_moves_towards_sample_and_saturates() {
        assert_eq!(rust_ema_q16(0, 1000, 65536), 1000);
        assert_eq!(rust_ema_q16(0, 1000, 32768), 500);
        assert_eq!(rust_ema_q16(100, 100, 6554), 100);
        assert_eq!(rust_ema_q16(i32::MAX, i32::MAX, 70000), i32::MAX);
    }
}
