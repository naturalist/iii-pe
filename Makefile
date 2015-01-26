PID_FILE=.iiipe.pid
STATUS_FILE=.iiipe.stat
PORT=8082
APP=app.psgi

help:
	@echo "install           install all dependencies"
	@echo "start             start the application in development mode"
	@echo "deploy            start the application in in deployment mode"
	@echo "test              run all tests"
	@echo "restart           restart the deployed app"
	@echo "debug             start in the perl debugger"

install:
	carton

start:
	carton exec plackup -r -a $(APP)

deploy:
	start_server --port=$(PORT) \
	             --pid-file=$(PID_FILE) \ 
				 --status-file=$(STATUS_FILE) \ 
				 -- \
				 carton exec plackup -s Starman --workers 1 -E deployment $(APP)

restart:
	start_server --restart --pid-file=$(PID_FILE) --status-file=$(STATUS_FILE)

test:
	carton exec prove -lv

debug:
	carton exec perl -d $(which plackup) $(APP)
