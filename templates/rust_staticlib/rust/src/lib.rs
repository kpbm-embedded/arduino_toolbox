//! @NAME@_rs: Rust code for the @NAME@ sketch (no_std, C ABI). Declare every export in include/@NAME@_rs.h.
#![cfg_attr(not(test), no_std)]

/// Saturating 16-bit add, an example export.
#[no_mangle]
pub extern "C" fn @NAME@_add_sat(a: i16, b: i16) -> i16 {
    a.saturating_add(b)
}

#[cfg(not(test))]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[cfg(test)]
mod tests {
    #[test]
    fn add_saturates() {
        assert_eq!(super::@NAME@_add_sat(30000, 10000), i16::MAX);
        assert_eq!(super::@NAME@_add_sat(-2, 1), -1);
    }
}
