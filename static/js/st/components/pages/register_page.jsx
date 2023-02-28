import * as React from "react"

import {Link, Navigate} from "react-router-dom"
import {setTitle} from "st/globals"
import {JsonForm, TextInputRow} from "st/components/forms"

import {init as initApp, getSession} from "st/app"

export default class RegisterPage extends React.Component {
  componentDidMount() {
    setTitle("Register Account")
  }

  afterSubmit(res) {
    if (res.errors) {
      this.setState({
        errorMessage: res.errors[0]
      })
      return
    }

    initApp(res)
    this.setState({ redirectTo: "/" })
  }

  constructor() {
    super()
    this.state = {}
  }

  render() {
    if (this.state.redirectTo) {
      return <Navigate replace to={this.state.redirectTo} />
    }

    if (getSession().currentUser) {
      return <Navigate replace to="/" />
    }

    return <div className="register_page page_container">
      <h2>Register</h2>
      <p>Create an account to keep track of your progress over time.</p>

      <JsonForm action="/register.json" afterSubmit={this.afterSubmit.bind(this)}>
        {this.state.errorMessage ? <div className="form_error">{this.state.errorMessage}</div> : null}
        <TextInputRow name="username" required={true}>Username</TextInputRow>
        <TextInputRow name="email" type="email" required={true}>Email address</TextInputRow>
        <TextInputRow name="password" type="password" required={true}>Password</TextInputRow>
        <TextInputRow name="password_repeat" type="password" required={true}>Confirm password</TextInputRow>

        <div className="form_buttons">
          <button className="big_button">Submit</button>
          {" or "}
          <Link to="/login">Log in to existing account</Link>
        </div>
      </JsonForm>
    </div>
  }
}
