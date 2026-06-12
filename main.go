package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/joshdurbin/linux_study/internal/db"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func main() {
	root := &cobra.Command{
		Use:   "linux_study",
		Short: "Linux fundamentals study guide: interactive terminal + analytics",
	}

	root.PersistentFlags().String("config", "", "config file (default: ./linux_study.yaml)")
	root.PersistentFlags().String("db", "linux_study.db", "SQLite database path")
	root.PersistentFlags().String("root", ".", "repo root containing linux/ curriculum")
	_ = viper.BindPFlag("db", root.PersistentFlags().Lookup("db"))
	_ = viper.BindPFlag("root", root.PersistentFlags().Lookup("root"))

	cobra.OnInitialize(initConfig)
	root.AddCommand(serveCmd(), versionCmd())

	if err := root.Execute(); err != nil {
		os.Exit(1)
	}
}

func initConfig() {
	viper.AddConfigPath(".")
	viper.SetConfigName("linux_study")
	viper.SetConfigType("yaml")
	viper.SetEnvPrefix("LINUX_STUDY")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_", "-", "_"))
	viper.AutomaticEnv()
	viper.SetDefault("addr", ":8080")
	viper.SetDefault("analytics_enabled", true)
	_ = viper.ReadInConfig()
}

func serveCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "serve",
		Short: "Run the Linux study web server",
		RunE: func(cmd *cobra.Command, args []string) error {
			return runServe()
		},
	}
	cmd.Flags().String("addr", ":8080", "listen address")
	cmd.Flags().Bool("analytics", true, "enable analytics tracking")
	_ = viper.BindPFlag("addr", cmd.Flags().Lookup("addr"))
	_ = viper.BindPFlag("analytics_enabled", cmd.Flags().Lookup("analytics"))
	return cmd
}

func versionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("linux_study v1.0.0")
		},
	}
}

func openDB() (*sql.DB, error) {
	path := viper.GetString("db")
	if dir := filepath.Dir(path); dir != "." && dir != "" {
		_ = os.MkdirAll(dir, 0o755)
	}
	conn, err := db.Open(path)
	if err != nil {
		log.Printf("open db %s: %v", path, err)
		return nil, err
	}
	return conn, nil
}
