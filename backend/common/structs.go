package common

type Alarm struct {
	DeviceID   string      `json:"deviceID"`
	MatchID    string      `json:"-"`
	GameAlarms []GameAlarm `json:"-"`
}

type GameAlarm struct {
	GameNumber int    `json:"-"`
	Trigger    string `json:"trigger"`
	Delay      int    `json:"delay"`
}
