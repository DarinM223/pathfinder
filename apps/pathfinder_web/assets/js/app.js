// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

import React, { Component, PropTypes } from 'react'
import ReactDOM from 'react-dom'
import {observable, computed} from 'mobx'
import {observer} from 'mobx-react'

class Todo {
  id = Math.random()
  @observable title
  @observable finished = false

  constructor (title) {
    this.title = title
  }
}

class TodoList {
  @observable todos = []

  @computed get unfinishedTodoCount () {
    return this.todos.filter(todo => !todo.finished).length
  }
}

@observer
class TodoListView extends Component {
  render () {
    return (
      <div>
        <ul>
          {this.props.todoList.todos.map(todo =>
            <TodoView todo={todo} key={todo.id} />
          )}
        </ul>

        Tasks left: {this.props.todoList.unfinishedTodoCount}
      </div>
    )
  }
}

const TodoView = observer(({todo}) =>
  <li>
    <input
      type="checkbox"
      checked={todo.finished}
      onClick={() => todo.finished = !todo.finished}
    />{todo.title}
  </li>
)

const store = new TodoList()

store.todos.push(new Todo("Item 1"))
store.todos.push(new Todo("Item 2"))

ReactDOM.render(
  <TodoListView todoList={store} />,
  document.getElementById('game')
)
