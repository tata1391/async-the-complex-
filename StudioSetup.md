# Studio setup

1. Install Rojo and open this folder.
2. Run `rojo serve default.project.json`.
3. In Roblox Studio, open the Rojo plugin and connect.
4. In **Game Settings → Avatar**, use the experience's normal avatar settings. The server marks a player `AsyncPhase = HUB` or `EMPLOYEE`; outfit swapping is intentionally deferred to the Level slice.
5. Press **Play**. Walk from Security Arrival to one of the six identical chambers and press **E** at its terminal.
6. Select capacity and visibility. The first player is host. Use **CREATE / JOIN**; a team fills automatically or starts after the timer. Use **START AS HOST** to preview the portal cinematic.

## Studio test checklist

- Test with **Test → Start** and 1–4 players.
- Public: another test client can join the same chamber.
- Friends/Private: the server rechecks the policy; private uses the displayed eight-character code.
- Leave or respawn clears membership and returns the character to Security Arrival.
- Set `Config.Teleport.Enabled = true` only in a published experience and provide a valid destination PlaceId.

## Troubleshooting

- If no geometry appears, check the Server Output for `[Async] Hub 0.2.0` and verify `Shared` is under `ReplicatedStorage`.
- If the intro did not play, respawn once; the client-ready handshake prevents a one-shot RemoteEvent from being missed.
- If an old generated hub remains, stop and restart the server; `HubBuilder` replaces `workspace.AsyncHub` on startup.
