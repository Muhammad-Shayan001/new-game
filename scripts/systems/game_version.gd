class_name GameVersion
extends RefCounted
## Single place for every version number. Bump deliberately and add a migration
## (see docs/DATA_SCHEMA.md, "Version compatibility").

const GAME_VERSION := "0.2.0"
const SAVE_VERSION := 3
const MIN_SUPPORTED_SAVE_VERSION := 1
const DATA_SCHEMA_VERSION := 2
const SETTINGS_VERSION := 1
