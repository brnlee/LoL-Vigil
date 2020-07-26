package common

type Alarm struct {
	DeviceID   string `json:"deviceID"`
	MatchID    string `json:"-"`
	GameNumber int64  `json:"-"`
	Trigger    string `json:"trigger"`
	Delay      int64  `json:"delay"`
}
