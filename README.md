# ASYNC: THE COMPLEX — Hub Vertical Slice 0.2

A Rojo-compatible, server-authoritative Roblox hub prototype for a co-op horror experience. This slice builds six identical rectangular Threshold chambers around a concrete observation corridor, a raised Control Gallery, a secured reception spawn, and a hidden-ready session flow.

## Included

- Six industrial portal chambers: armored rectangular threshold, blue tanks, conduit, cable runs, rails, safety line, indicator and status label.
- Central observation corridor with chamber openings, security arrival, equipment lockers and control-gallery stair.
- Server-owned session creation for 1–4 players.
- Public, Friends-only and Private sessions with host capacity and private code.
- Level 0 unlocked; later level records are present but locked.
- ProximityPrompt portal terminals and RemoteEvent-based UI.
- Intro cinematic and portal activation cinematic with mobile/keyboard skip.
- Test mode is intentionally enabled by default; no external assets are required.
- Teleport path is implemented but disabled until a published destination PlaceId exists.

## Run

```bash
rojo serve default.project.json
```

Connect the Rojo plugin in Roblox Studio, then press **Play**. For a no-Rojo install, copy the folders under `src` to their matching Roblox services; see [`StudioSetup.md`](StudioSetup.md).

## Important Studio settings

- Set `Workspace.StreamingEnabled = true` after the first geometry pass.
- Set the experience's maximum server size to 4 for the hub test place.
- Keep `Config.Teleport.Enabled = false` while testing in Studio. When Level 0 has its own published Place, set the PlaceId and enable it from the server config.
- Add only audio, video, textures and meshes that the team owns or is licensed to use. Empty audio IDs are intentional.

## Scope boundary

This is the playable Hub slice: reception → portal panel → team session → chamber cinematic. Level gameplay, AI and the Lost Human phase belong to the next vertical slice and are not falsely represented as complete here.
