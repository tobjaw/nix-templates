package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/signal"
)

var (
	flags  = flag.NewFlagSet("examplecli", flag.ExitOnError)
	errCLI = errors.New("CLI")
)

func usage() {
	fmt.Println(`
examplecli
	TODO: tool description

Usage:
	TODO: command description

Global options:`)
	flags.PrintDefaults()
	os.Exit(1)
}

func main() {
	ctx := context.Background()
	if err := run(ctx, os.Args, os.Stdout, os.Stdin); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		if errors.Is(err, errCLI) {
			usage()
		}
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string, stdout io.Writer, stdin io.Reader) error {
	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()

	var (
		logLevel = flags.String("log.level", "info", "log level to use (debug, info, warn, error)")
	)

	flags.Usage = usage
	if err := flags.Parse(args[1:]); err != nil {
		return fmt.Errorf("%w: parse args: %w", errCLI, err)
	}

	var l slog.Level
	if err := l.UnmarshalText([]byte(*logLevel)); err != nil {
		return fmt.Errorf("%w: parse log.level: %w", errCLI, err)
	}
	handler := slog.NewTextHandler(stdout, &slog.HandlerOptions{
		Level: l,
	})
	log := slog.New(handler)

	cmds := flags.Args()
	if len(cmds) == 0 {
		return fmt.Errorf("%w: missing command", errCLI)
	}
	if len(cmds) >= 2 {
		return fmt.Errorf("%w: extra args: %v", errCLI, args[1:])
	}
	cmd := cmds[0]

	log.Debug("run", "cmd", cmd)

	return nil
}
