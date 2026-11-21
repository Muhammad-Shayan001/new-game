class_name TimeEchoDef
extends GameDef
## A short replay of a past event: timeline data for figures, camera, audio, captions
## and clue moments. Played by TimeEchoManager at an EchoSite.

@export var title_key: String = ""
@export var location_id: String = ""
@export var duration: float = 10.0
@export var tracks: Array[EchoTrack] = []
@export var camera_keys: Array[EchoCameraKey] = []
@export var audio_events: Array[EchoAudioEvent] = []
@export var captions: Array[EchoCaption] = []
@export var clue_moments: Array[EchoClueMoment] = []
## The echo can only be played while these are met (e.g. a clue found earlier).
@export var conditions: ConditionSet
@export var replayable: bool = true
@export var set_flags: Array[String] = []

func kind() -> String:
	return "echo"

func validate() -> Array[String]:
	var errors := super.validate()
	if duration <= 0.0 or duration > 30.0:
		errors.append("%s: duration must be between 0 and 30 seconds" % id)
	if tracks.is_empty():
		errors.append("%s: an echo needs at least one track" % id)
	for t in tracks:
		var last := -1.0
		for k in t.keys:
			if k.time < last or k.time > duration:
				errors.append("%s/%s: keys must be time-ordered and inside the duration" % [id, t.actor_id])
				break
			last = k.time
	for c in clue_moments:
		if c.time > duration:
			errors.append("%s: clue moment after the end" % id)
		if c.clue_id != "" and not IdRules.is_valid("clue", c.clue_id):
			errors.append("%s: bad clue id '%s'" % [id, c.clue_id])
	for e in audio_events:
		if not IdRules.is_valid("audio", e.cue_id):
			errors.append("%s: bad audio cue id '%s'" % [id, e.cue_id])
	return errors
