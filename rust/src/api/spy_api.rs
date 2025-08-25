use flutter_rust_bridge::frb;

use crate::{
    frb_generated::StreamSink,
    spy::{api::EVENT_SINK, model::Application},
};

#[frb(sync)]
pub fn application_info_stream(s: StreamSink<Application>) -> anyhow::Result<()> {
    let mut stream = EVENT_SINK.write().unwrap();
    *stream = Some(s);
    anyhow::Ok(())
}

#[frb(sync)]
pub fn start_spy() {
    crate::spy::api::start_spy();
}

#[frb(sync)]
pub fn get_spy_status() -> bool {
    crate::spy::api::SPY_ON.read().unwrap().clone()
}
