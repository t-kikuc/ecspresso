package secretsmanager

import "sync"

func MockNewApp(client secretsmanagerClient) *App {
	return &App{
		svc:   client,
		cache: &sync.Map{},
	}
}
