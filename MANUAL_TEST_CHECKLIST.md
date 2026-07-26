# Manual Test Checklist

## Startup

- Fresh install opens without crash.
- App restarts after force close.
- App survives background/foreground.
- App opens after device reboot.

## Scanner

- Camera permission allowed.
- Camera permission denied.
- Camera permission permanently denied.
- Flash toggle works on supported devices.
- Duplicate scan debounce works.
- Invalid barcode is rejected.
- Manual barcode input works.

## API

- Online product found.
- Product not found.
- Offline with no cache.
- Offline with cached product.
- Slow network / timeout.
- Incomplete product data.

## Product UI

- Long product name.
- Missing image.
- Missing nutrition.
- Long ingredients text.
- Allergens displayed.
- Additives displayed.
- Favorite add/remove.

## Storage

- History persists across app restart.
- Favorites persist across app restart.
- Delete history item.
- Clear history.
- Clear product cache.
- Corrupted old data does not crash.

## Android

- Real device fresh install.
- Launch from icon.
- Scan real barcode.
- Rotate / return from background.

## iOS

- Real iPhone fresh install.
- Camera permission dialog text is correct.
- Camera scan works.
- Permission denied flow is understandable.
- Dark mode.
- Dynamic Type.
- RTL layout if Arabic support is enabled later.
- TestFlight install.
- No crash during first launch.

