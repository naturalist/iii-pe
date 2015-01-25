PID_FILE=.iiipe.pid
STATUS_FILE=.iiipe.stat
PORT=8082

help:
	@echo "start    start in development"
	@echo "deploy   start in deployment"
	@echo "test     run all tests"
	@echo "restart  restart deployed app"
	@echo "debug    start in debugger"

start:
	carton exec plackup -r -a app.psgi

deploy:
	start_server --port=$(PORT) --pid-file=$(PID_FILE) --status-file=$(STATUS_FILE) -- plackup -s Starman -E deployment app.psgi

restart:
	start_server --restart --pid-file=$(PID_FILE) --status-file=$(STATUS_FILE)

test:
	carton exec prove -lv

debug:
	carton exec perl -d $(which plackup) app.psgi
