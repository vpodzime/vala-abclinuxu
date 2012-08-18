PROGRAM_NAME=DoNotForget

#all: tasks.vala do_not_forget.vala
#	@echo "Compiling $(PROGRAM_NAME)"
#	valac do_not_forget.vala tasks.vala -o $(PROGRAM_NAME)

test: tasks_test.vala tasks.vala
	@echo "Compiling tests"
	valac tasks_test.vala tasks.vala
	@echo
	@echo "Running tasks_test.vala"
	@./tasks_test

clean:
	-@rm $(PROGRAM_NAME)
	-@rm tasks_test
