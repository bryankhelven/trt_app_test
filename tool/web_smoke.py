"""Compatibility entry point for the current real-browser acceptance suite."""
import asyncio
from web_acceptance import main
if __name__ == '__main__':
    asyncio.run(main())
