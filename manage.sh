#!/bin/bash

# ERPNext Management Script

set -e

function show_help() {
    echo "ERPNext Management Script"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start      - Start all services"
    echo "  stop       - Stop all services"
    echo "  restart    - Restart all services"
    echo "  logs       - Show logs from all services"
    echo "  status     - Show status of all services"
    echo "  console    - Open Frappe console"
    echo "  clear-queue - Clear Redis queues"
    echo "  import-test - Test data import functionality"
    echo "  help       - Show this help message"
}

function start_services() {
    echo "Starting ERPNext services..."
    docker compose -f docker-compose-fixed.yaml up -d
    echo "Services started successfully!"
    echo "Access ERPNext at: http://localhost:8080"
    echo "Admin credentials: admin/admin"
}

function stop_services() {
    echo "Stopping ERPNext services..."
    docker compose -f docker-compose-fixed.yaml down
    echo "Services stopped!"
}

function restart_services() {
    echo "Restarting ERPNext services..."
    stop_services
    start_services
}

function show_logs() {
    if [ -n "$2" ]; then
        docker compose -f docker-compose-fixed.yaml logs -f "$2"
    else
        docker compose -f docker-compose-fixed.yaml logs -f
    fi
}

function show_status() {
    docker compose -f docker-compose-hrms.yaml ps
}

function open_console() {
    docker compose -f docker-compose-hrms.yaml exec backend bench --site frontend console
}

function clear_queues() {
    echo "Clearing Redis queues..."
    docker compose -f docker-compose-hrms.yaml exec redis-queue redis-cli FLUSHALL
    echo "Queues cleared!"
}

function test_import() {
    echo "Testing data import functionality..."
    echo "Checking queue workers..."
    docker compose -f docker-compose-hrms.yaml logs queue-long --tail 5
    docker compose -f docker-compose-hrms.yaml logs queue-short --tail 5
    echo "Queue workers status checked!"
}

case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs "$@"
        ;;
    status)
        show_status
        ;;
    console)
        open_console
        ;;
    clear-queue)
        clear_queues
        ;;
    import-test)
        test_import
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
