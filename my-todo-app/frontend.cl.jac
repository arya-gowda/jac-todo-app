"""Todo App - Client-Side UI."""

import from "@jac/runtime" { jacSignup, jacLogin, jacLogout, jacIsLoggedIn }

import "./styles.css";

import from .components.TodoItem { TodoItem }
import from .components.AuthForm { AuthForm }
import from .components.IngredientItem { IngredientItem }

sv import from main {
    AddTodo, ListTodos, ToggleTodo, DeleteTodo,
    GenerateShoppingList, ListMealPlan, ClearMealPlan
}

def:pub app -> any {
    has isLoggedIn: bool = False,
        checkingAuth: bool = True,
        isSignup: bool = False,
        username: str = "",
        password: str = "",
        error: str = "",
        loading: bool = False,
        todos: list = [],
        newTodoText: str = "",
        todosLoading: bool = True,
        mealInput: str = "",
        ingredients: list = [],
        ingredientsLoading: bool = False,
        isDarkMode: bool = False,
        searchText: str = "",
        filterStatus: str = "all"; # "all", "active", "completed"

    can with entry {
        isLoggedIn = jacIsLoggedIn();
        checkingAuth = False;

        # Restore theme preference from localStorage (if available)
        if typeof(localStorage) != "undefined" {
            saved = localStorage.getItem("isDarkMode");
            if saved != None {
                isDarkMode = (saved == "true");
            }
        }
    }

    can with [isLoggedIn] entry {
        if isLoggedIn {
            fetchTodos();
            fetchMealPlan();
        }
    }

    # Sync theme to document body so background/styles apply globally
    can with entry {
        if typeof(document) != "undefined" {
            if isDarkMode {
                document.body.classList.add("dark-theme");
                document.body.classList.remove("light-theme");
            } else {
                document.body.classList.add("light-theme");
                document.body.classList.remove("dark-theme");
            }
        }
    }

    can with [isDarkMode] entry {
        if typeof(document) != "undefined" {
            if isDarkMode {
                document.body.classList.add("dark-theme");
                document.body.classList.remove("light-theme");
            } else {
                document.body.classList.add("light-theme");
                document.body.classList.remove("dark-theme");
            }
        }

        # Persist preference
        if typeof(localStorage) != "undefined" {
            localStorage.setItem("isDarkMode", ("true" if isDarkMode else "false"));
        }
    }

    # Method declarations (implementations in frontend.impl.jac)
    async def fetchTodos -> None;
    async def addTodo -> None;
    async def toggleTodo(todoId: str) -> None;
    async def deleteTodo(todoId: str) -> None;
    async def handleLogin -> None;
    async def handleSignup -> None;
    def handleLogout -> None;
    async def handleSubmit(e: any) -> None;
    def handleTodoKeyPress(e: any) -> None;
    async def fetchMealPlan -> None;
    async def generateIngredients -> None;
    async def clearIngredients -> None;
    def handleMealKeyPress(e: any) -> None;
    def getIngredientsTotal -> float;

    if checkingAuth {
        return
            <div style={{"display": "flex", "justifyContent": "center",
                         "alignItems": "center", "minHeight": "100vh",
                         "color": "rgba(255,255,255,0.6)", "fontFamily": "system-ui"}}>
                Loading...
            </div>;
    }

    if isLoggedIn {
        totalCost = getIngredientsTotal();
        return (
            <div className={ "app-container " + ("dark-theme" if isDarkMode else "light-theme") }>
                <button onClick={lambda -> None { isDarkMode = not isDarkMode; }} className="btn-theme-toggle">
                    { "🌙 Dark Mode" if not isDarkMode else "☀️ Light Mode" }
                </button>
                <div className="app-content">
                    <div className="card">
                        <div className="card-header">
                            <div>
                                <h1 className="app-title">TaskFlow</h1>
                                <p className="app-subtitle">
                                    Todo list with AI meal planning
                                </p>
                            </div>
                            <button onClick={handleLogout} className="btn-signout">
                                Sign Out
                            </button>
                        </div>
                    </div>
                    <div className="two-column-layout">
                        <div className="column-left">
                            <div className="card">
                                <div className="add-row">
                                    <input
                                        type="text"
                                        value={newTodoText}
                                        onChange={lambda e: any -> None { newTodoText = e.target.value; }}
                                        onKeyPress={handleTodoKeyPress}
                                        placeholder="What needs to be done?"
                                        className="todo-input"
                                    />
                                    <button
                                        onClick={lambda -> None { addTodo(); }}
                                        className="btn-add"
                                    >
                                        Add
                                    </button>
                                </div>
                            </div>
                            <div className="card">
                                {(
                                    <div className="loading-message">Loading tasks...</div>
                                ) if todosLoading else (
                                    <div>
                                        <div className="controls">
                                            <input
                                                className="input"
                                                placeholder="Search todos..."
                                                value={searchText}
                                                onChange={lambda e: any -> None { searchText = e.target.value; }}
                                            />
                                            <select
                                                className="select-filter"
                                                onChange={lambda e: any -> None { filterStatus = e.target.value; }}
                                            >
                                                <option value="all">All</option>
                                                <option value="active">Active</option>
                                                <option value="completed">Completed</option>
                                            </select>
                                        </div>

                                        {(
                                            <div className="empty-message">
                                                No tasks yet. Add one above!
                                            </div>
                                        ) if todos.length == 0 else (
                                            <div>
                                                {[
                                                    <TodoItem
                                                        key={t.id}
                                                        todo={t}
                                                        onToggle={toggleTodo}
                                                        onDelete={deleteTodo}
                                                    /> for t in todos
                                                    if (searchText.lower() in t.title.lower()) and (
                                                        filterStatus == "all" or
                                                        (filterStatus == "active" and not t.completed) or
                                                        (filterStatus == "completed" and t.completed)
                                                    )
                                                ]}
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>
                            <div className="remaining-count">
                                {todos.filter(
                                    lambda t: any -> bool { return not t.completed; }
                                ).length} items remaining
                            </div>
                        </div>
                        <div className="column-right">
                            <div className="card">
                                <h2 className="panel-title">Meal Planner</h2>
                                <p className="panel-subtitle">
                                    Describe a meal to generate a shopping list
                                </p>
                                <div className="add-row">
                                    <input
                                        type="text"
                                        value={mealInput}
                                        onChange={lambda e: any -> None { mealInput = e.target.value; }}
                                        onKeyPress={handleMealKeyPress}
                                        placeholder="e.g. spaghetti bolognese for 4"
                                        className="todo-input"
                                    />
                                    <button
                                        onClick={lambda -> None { generateIngredients(); }}
                                        disabled={ingredientsLoading}
                                        className="btn-generate"
                                    >
                                        {("Generating..." if ingredientsLoading else "Generate")}
                                    </button>
                                </div>
                            </div>
                            <div className="card">
                                {(
                                    <div className="loading-message">
                                        <div className="generating-spinner"></div>
                                        Generating shopping list with AI...
                                    </div>
                                ) if ingredientsLoading else (
                                    <div>
                                        {(
                                            <div className="empty-message">
                                                Enter a meal above to generate ingredients.
                                            </div>
                                        ) if ingredients.length == 0 else (
                                            <div>
                                                {[
                                                    <IngredientItem
                                                        key={ing.name}
                                                        ingredient={ing}
                                                    /> for ing in ingredients
                                                ]}
                                                <div className="ingredients-footer">
                                                    <div className="ingredients-total">
                                                        Total: ${totalCost.toFixed(2)}
                                                    </div>
                                                    <button
                                                        onClick={lambda -> None { clearIngredients(); }}
                                                        className="btn-clear"
                                                    >
                                                        Clear
                                                    </button>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    return
        <AuthForm
            isSignup={isSignup}
            username={username}
            password={password}
            error={error}
            loading={loading}
            onUsernameChange={lambda e: any -> None { username = e.target.value; }}
            onPasswordChange={lambda e: any -> None { password = e.target.value; }}
            onSubmit={handleSubmit}
            onToggleMode={lambda -> None { isSignup = not isSignup; error = ""; }}
        />;
}