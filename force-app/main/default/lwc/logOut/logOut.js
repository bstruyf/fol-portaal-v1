import { LightningElement } from 'lwc';

export default class LogoutButton extends LightningElement {
  handleLogout() {
    // stuurt de gebruiker naar de standaard Salesforce logout-pagina
    // retUrl kun je aanpassen naar de pagina waar je na uitloggen heen wilt sturen
    window.location.href = '/secur/logout.jsp?retUrl=https://farmad--sandbox2.sandbox.my.site.com/FOLPortaal/';
  }
}