# Upstream status, 2026-11-28 (web/GitHub read by a sonnet agent; self-reported claims, not verified)

| source | claim | iOS |
| --- | --- | --- |
| dipa-studio/ios-sweet README (last push 2026-10-23) | home screen, CPU rendering, 20-30 fps, no GPU/sensors | 16.7.16 |
| DC28088 / Dana README (2026-11-09) | home screen + native Metal ~37 fps; auto-brightness not working | 16.7.16 |
| DC28088 NOTES (to 2026-11-27) | SpringBoard on GPU stable on 26cF/26cJ; swipes 60 fps 70-77 % of the time | 26.6.2 (`xnu/patches-12377`) |
| Dana NOTES (to 2026-11-17) | 26bB-26bE flicker fixes | 26.6.2 |

- No published full cmdline or root image; no releases. Only iOS 16 fragment: `sweetpanelvci=0 sweetmotion=0xbf sweetfbflip=1 sweetfbgpu=1`.
- Their iOS 16 Metal bundle was a separate build: `SweetMetal2.bundle.ios16-e0574fa` (CI 42213344710). Current native-metal targets iOS 26.
- No respring-loop or ALS/MobileGestalt hang reports upstream. iOS 26 26cG/26cH: SpringBoard MPS aborts -> launchd reboot; fixed 26cI.
- Consequence for us (`TEST_LOG` d02/d03): the bundle we built from current donor is iOS 26-era; our iOS 16 base stays `gpu`.
