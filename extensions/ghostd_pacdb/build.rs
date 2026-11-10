//! The Windows DLL's file properties (Explorer > Properties > Details): who
//! made it and what it is. Nothing on Linux.

fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    #[cfg(windows)]
    {
        let mut res = winresource::WindowsResource::new();
        res.set("FileDescription", "TAC//PAC database extension for the Arma 3 server (JMSB mod)")
            .set("ProductName", "JMSB mod")
            .set("CompanyName", "1st Joint Multi-Functional Strike Battalion")
            .set("LegalCopyright", "YonV and the 1st JMSB contributors")
            .set("InternalName", "ghostd_pacdb")
            .set("OriginalFilename", "ghostd_pacdb_x64.dll");
        if let Err(e) = res.compile() {
            panic!("file properties: {e}");
        }
    }
}
