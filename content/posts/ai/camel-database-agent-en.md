## Pain Points in Data Analysis and Solutions

In today's data-driven business environment, a common scenario is: business analysts urgently need certain data analysis but must wait for technical team members who know SQL to provide support. According to a McKinsey study, analysts spend an average of 30-40% of their time just on data preparation and query construction. This dependency not only delays the decision-making process but also increases the workload of the technical team.

**This is why I developed CAMEL DatabaseAgent** — a revolutionary open-source tool that allows anyone to converse with databases using natural language, as simply as talking to a colleague. Without writing a single line of SQL code, analysts can directly obtain the data insights they need.

## Core Advantages of CAMEL DatabaseAgent

Compared to other text-to-SQL tools on the market, CAMEL DatabaseAgent has the following significant advantages:

1. **Fully open-source**: Transparent code and community-driven development ensure continuous improvement and customization flexibility
2. **Multi-language support**: Ability to understand and respond to queries in multiple languages including Chinese, English, and Korean
3. **Automatic database understanding**: Analyzes database structure and generates appropriate few-shot learning examples
4. **Read-only mode**: Default safe operation that protects databases from accidental modifications
5. **Simple integration**: Easy to integrate with existing systems and workflows

## Technical Architecture: How It Works

CAMEL DatabaseAgent is built on the [CAMEL-AI](https://github.com/camel-ai/camel) and consists of three core components:

1. **DataQueryInferencePipeline**: This intelligent component analyzes your database structure and automatically generates training examples, including questions and corresponding SQL queries. It uses advanced inference techniques to understand relationships between tables and the semantics of the data.

2. **DatabaseKnowledge**: A specially designed vector database for efficiently storing and retrieving database schemas, sample data, and query patterns. This component enables the system to quickly "recall" relevant database knowledge to answer user questions.

3. **DatabaseAgent**: An intelligent agent based on large language models (LLMs) that receives natural language questions, uses DatabaseKnowledge to generate precise SQL queries, executes queries, and returns results in a user-friendly format.

Supported database systems include:
- SQLite
- MySQL
- PostgreSQL

All operations are performed in read-only mode by default, ensuring data security.

## Real-world Application Cases: From Simple to Complex

I tested this tool on a real database from a music distribution platform, and the results were impressive. Here are several application scenarios in increasing order of complexity:

### Basic Queries
When I asked "Find the names of playlists containing more than 10 tracks," the system immediately generated the correct SQL:


![Basic Queries](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/p59967pz7aa1s5zfwy5l.png)
*The system can understand simple filtering and counting requirements*

### Medium Complexity Queries
**Scenario 1**: Statistics on sales data within a specific time period
![Statistics on sales data within a specific time period](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/euwl7x1vsguxb261q6jp.png)
*The system successfully handled multi-table joins and time range filtering*

**Scenario 2**: Financial analysis grouped by category
![Financial analysis grouped by category](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/xqszsb3f3iz8sz2x0y9l.png)
*The system can understand grouping, aggregation, and complex table relationships*

### Advanced Analysis Queries
**Scenario 3**: Performance ranking analysis
![Performance ranking analysis](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/rqnoz17bfj4i8hlmd9h5.png)
*The system handled multi-table joins, sorting, and limit conditions*

**Scenario 4**: Conditional filtering and counting
![Conditional filtering and counting](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/9njyfdoqbo6vqptwlfwh.png)
*The system can use subqueries and complex conditions*

**Scenario 5**: Percentage calculation
![Percentage calculation](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/2sixx8svti4cna9fiame.png)
*The system can perform mathematical calculations and conditional counting*

**Scenario 6**: Complex relational analysis
![Complex relational analysis](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/hbt974z5gjkc7ytt33xi.png)
*The system can handle left joins and null value situations*

## Breaking Language Barriers: Multi-language Support

In globalized team environments, language barriers are often bottlenecks for data collaboration. CAMEL DatabaseAgent supports multi-language interaction, allowing team members from different language backgrounds to train knowledge and perform data queries in their native languages.

![Chinese](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ud9hu1y88lxhaom0njuq.png)
*Training knowledge and asking questions in Chinese*

![Korean](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/oy86w2j11aby26duxfts.png)
*The system also supports other languages like Korean, and all you need to do is specify the language when connecting to the database*

## Getting Started Guide: Up and Running in 5 Minutes

Want to try CAMEL DatabaseAgent? Just a few simple steps:

```shell
# 1. Clone the repository
git clone git@github.com:coolbeevip/camel-database-agent.git
cd camel-database-agent

# 2. Set up the environment
pip install uv ruff mypy
uv venv .venv --python=3.10
source .venv/bin/activate
uv sync --all-extras

# 3. Configure API keys
export OPENAI_API_KEY=sk-xxx
export OPENAI_API_BASE_URL=https://api.openai.com/v1/
export MODEL_NAME=gpt-4o-mini

# 4. Connect to the sample database and start using
python camel_database_agent/cli.py \
--database-url sqlite:///database/sqlite/music.sqlite
```

On first connection, the system will spend a few minutes analyzing the database and generating a knowledge base. Subsequent use will be very smooth, with response times typically within 1-3 seconds.

## Integration API for Developers

For developers who wish to integrate this functionality into their own applications or systems, we provide a concise Python API:

```python
# Install the dependency library
pip install camel-database-agent

# Initialize the database agent
from camel_database_agent import DatabaseAgent, DatabaseManager, TrainLevel
from camel_database_agent.models import ModelFactory, OpenAIEmbedding
import uuid

database_agent = DatabaseAgent(
    interactive_mode=True,
    database_manager=DatabaseManager(db_url=database_url),
    model=ModelFactory.create(
        provider="openai",
        model_name="gpt-4o-mini"
    ),
    embedding_model=OpenAIEmbedding()
)

# Train the agent on database schema knowledge
database_agent.train_knowledge(level=TrainLevel.MEDIUM)

# Execute queries using natural language
response = database_agent.ask(
    session_id=str(uuid.uuid4()),
    question="List all playlists containing more than 5 tracks"
)

# Process the returned results
print(response.answer)  # Natural language answer
print(response.sql)     # Generated SQL query
print(response.data)    # Structured query results
```

## Conclusion

CAMEL DatabaseAgent represents the future of database interaction—making data queries as natural as everyday conversation. It not only improves the efficiency of data analysts but also empowers non-technical personnel to directly obtain data insights, thereby accelerating the decision-making process across the entire organization.

In the era of data democratization, tools should not be barriers to gaining insights. Through CAMEL DatabaseAgent, I hope to contribute to breaking down these barriers, allowing everyone to easily converse with data.

[GitHub](https://github.com/coolbeevip/camel-database-agent)

If you find this project valuable, don't forget to give it a star ⭐! Your support is the driving force behind the development of open-source projects!