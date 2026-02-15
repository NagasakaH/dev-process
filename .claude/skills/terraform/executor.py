#!/usr/bin/env python3
"""
MCP Skill Executor
==================
Handles dynamic communication with the MCP server.
Uses async context managers for proper MCP client lifecycle.
"""

import json
import sys
import asyncio
import argparse
from pathlib import Path

try:
    from mcp import ClientSession, StdioServerParameters
    from mcp.client.stdio import stdio_client
    HAS_MCP = True
except ImportError:
    HAS_MCP = False


async def run_mcp_operation(config: dict, operation: str, **kwargs):
    """Run an MCP operation within proper async context managers."""
    if not HAS_MCP:
        print("Error: mcp package not installed. Install with: pip install mcp", file=sys.stderr)
        sys.exit(1)

    server_params = StdioServerParameters(
        command=config["command"],
        args=config.get("args", []),
        env=config.get("env")
    )

    async with stdio_client(server_params) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()

            if operation == "list":
                response = await session.list_tools()
                tools = [{"name": t.name, "description": t.description} for t in response.tools]
                print(json.dumps(tools, indent=2, ensure_ascii=False))

            elif operation == "describe":
                tool_name = kwargs["tool_name"]
                response = await session.list_tools()
                for t in response.tools:
                    if t.name == tool_name:
                        print(json.dumps({
                            "name": t.name,
                            "description": t.description,
                            "inputSchema": t.inputSchema
                        }, indent=2, ensure_ascii=False))
                        return
                print(f"Tool not found: {tool_name}", file=sys.stderr)
                sys.exit(1)

            elif operation == "call":
                call_data = kwargs["call_data"]
                result = await session.call_tool(
                    call_data["tool"],
                    call_data.get("arguments", {})
                )
                for item in result.content:
                    if hasattr(item, 'text'):
                        print(item.text)
                    else:
                        print(json.dumps(
                            item.__dict__ if hasattr(item, '__dict__') else str(item),
                            indent=2, ensure_ascii=False
                        ))


def main():
    parser = argparse.ArgumentParser(description="MCP Skill Executor")
    parser.add_argument("--call", help="JSON tool call to execute")
    parser.add_argument("--describe", help="Get tool schema by name")
    parser.add_argument("--list", action="store_true", help="List all tools")
    args = parser.parse_args()

    config_path = Path(__file__).parent / "mcp-config.json"
    if not config_path.exists():
        print(f"Error: {config_path} not found", file=sys.stderr)
        sys.exit(1)

    with open(config_path) as f:
        config = json.load(f)

    try:
        if args.list:
            asyncio.run(run_mcp_operation(config, "list"))
        elif args.describe:
            asyncio.run(run_mcp_operation(config, "describe", tool_name=args.describe))
        elif args.call:
            call_data = json.loads(args.call)
            asyncio.run(run_mcp_operation(config, "call", call_data=call_data))
        else:
            parser.print_help()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
