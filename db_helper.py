import subprocess
import sys

def run_sql(query):
    """Execute SQL query on PostgreSQL database"""
    try:
        result = subprocess.run(
            [
                r"C:\Program Files\PostgreSQL\18\bin\psql.exe",
                "-U", "postgres",
                "-h", "127.0.0.1",
                "-d", "pdv_system",
                "-t", "-A",
                "-c", query
            ],
            env={"PGPASSWORD": "frentex"},
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            print(result.stdout.strip())
        else:
            error_msg = result.stderr.strip() if result.stderr else "Erro desconhecido"
            print(f"ERRO: {error_msg}")
            print(f"STDOUT: {result.stdout}")
            print(f"Return code: {result.returncode}")
            sys.exit(1)

    except Exception as e:
        print(f"ERRO: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python db_helper.py 'SELECT * FROM tabela'")
        sys.exit(1)

    query = sys.argv[1]
    run_sql(query)
