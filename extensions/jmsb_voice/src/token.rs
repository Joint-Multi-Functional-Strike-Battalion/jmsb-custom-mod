//! Join tokens. Signed only where the API secret is: the Arma server (and the
//! voicetest exe). A token lets a player into one room, publishing his
//! microphone and nothing else - no camera, no screen (video stays off).

use std::time::Duration;

use livekit_api::access_token::{AccessToken, VideoGrants};

/// How long a token may be used to join (s). Joining is at mission start or
/// after a drop, so this only needs to cover the trip to the client.
const TTL_S: u64 = 600;

pub fn mint(key: &str, secret: &str, room: &str, identity: &str, name: &str) -> Result<String, String> {
    let grants = VideoGrants {
        room_join: true,
        room: room.to_owned(),
        can_publish: Some(true),
        can_subscribe: Some(true),
        can_publish_data: Some(false),
        can_publish_sources: vec!["microphone".to_owned()],
        ..Default::default()
    };
    AccessToken::with_api_key(key, secret)
        .with_identity(identity)
        .with_name(name)
        .with_ttl(Duration::from_secs(TTL_S))
        .with_grants(grants)
        .to_jwt()
        .map_err(|e| e.to_string())
}
