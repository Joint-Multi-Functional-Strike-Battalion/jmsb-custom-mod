//! The Windows DLL's file properties (Explorer > Properties > Details): who
//! made it and what it is. An unnamed native DLL is what antivirus and
//! BattlEye look at hardest. Nothing on Linux.

fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    #[cfg(windows)]
    {
        let mut res = winresource::WindowsResource::new();
        res.set("FileDescription", "JMSB voice extension for Arma 3 (radio voice over LiveKit)")
            .set("ProductName", "JMSB mod")
            .set("CompanyName", "1st Joint Multi-Functional Strike Battalion")
            .set("LegalCopyright", "MIT License - YonV and the 1st JMSB contributors")
            .set("InternalName", "jmsb_voice")
            .set("OriginalFilename", "jmsb_voice_x64.dll");
        if let Err(e) = res.compile() {
            panic!("file properties: {e}");
        }
    }
}
