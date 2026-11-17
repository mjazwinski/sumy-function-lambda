import logging
from typing import Annotated

from langdetect import detect
from mcp.server.fastmcp import FastMCP
from pydantic import Field
from sumy.nlp.tokenizers import Tokenizer
from sumy.parsers.plaintext import PlaintextParser
from sumy.summarizers.lsa import LsaSummarizer

logger = logging.getLogger(__name__)

mcp = FastMCP(
    name="TestServer",
    instructions="Some test instructions on how to use the server",
    stateless_http=True,
    host="0.0.0.0",
)


@mcp.tool()
def summarizer_mcp(
    text: Annotated[str, Field(description="Text to summarize")],
    sentence_count: Annotated[
        int, Field(description="Number of sentences to put into summary. Default: 6.")
    ] = 6,
) -> str:
    """
    Sample function for text summarization
    """

    parser = PlaintextParser.from_string(text, Tokenizer(detect(text)))
    sentences = LsaSummarizer()(parser.document, sentence_count)

    logger.info("Summarizer tool invoked.")

    return str().join([str(sentence) for sentence in sentences])
