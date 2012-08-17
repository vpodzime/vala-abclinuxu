PROGRAM_NAME=DoNotForget

all: tasks.vala do_not_forget.vala
	@echo "Compiling $(PROGRAM_NAME)"
	valac do_not_forget.vala tasks.vala -o $(PROGRAM_NAME)

test: all
	@echo
	@echo "Running $(PROGRAM_NAME)"
	@./$(PROGRAM_NAME)

clean:
	-@rm $(PROGRAM_NAME)
