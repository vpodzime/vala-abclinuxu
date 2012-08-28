PROGRAM_NAME=DoNotForget
PKGS=gee-1.0
OPTS=--pkg=$(PKGS)

#all: tasks.vala do_not_forget.vala
#	@echo "Compiling $(PROGRAM_NAME)"
#	valac do_not_forget.vala tasks.vala -o $(PROGRAM_NAME)

test: tasks_test task_collections_test task_manager_test

task_collections_test:  task_collections_test.vala task_collections.vala tasks.vala
	@echo "================================"
	@echo "Compiling tests:"
	valac task_collections_test.vala task_collections.vala tasks.vala
	@echo
	@echo "Running task_collections_test.vala:"
	@./task_collections_test
	@echo "================================"
	@echo

tasks_test: tasks_test.vala tasks.vala
	@echo "================================"
	@echo "Compiling tests:"
	valac tasks_test.vala tasks.vala
	@echo
	@echo "Running tasks_test.vala:"
	@./tasks_test
	@echo "================================"
	@echo

task_manager_test: task_manager_test.vala task_manager.vala
	@echo "================================"
	@echo "Compiling tests:"
	valac $(OPTS) task_manager_test.vala task_manager.vala task_collections.vala tasks.vala
	@echo
	@echo "Running task_manager_test.vala:"
	@./task_manager_test
	@echo "================================"
	@echo

clean:
	-@rm $(PROGRAM_NAME) &> /dev/null
	-@rm tasks_test &> /dev/null
	-@rm task_collections_test &> /dev/null
	-@rm task_manager_test &> /dev/null
