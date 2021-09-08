<div id="search-drills">
	<%= form_with(url: '/drills', method: 'get', local: true) do %>
		<%= text_field_tag(:search) %>
		<%= submit_tag("Buscar") %>
	<% end %>
</div>

<div id="search-grid">
	<table>
		<thead>
			<tr>
				<th>Nombre</th>
				<th>Tipo</th>
				<th>Descripci&oacute;n</th>
				<th>Fundamentos</th>
			</tr>
		</thead>

		<tbody>
			<% @drills.each do |drill| %>
				<tr>
					<td><%= link_to drill.name, drill %></td>
					<td><%= drill.kind.name %></td>
					<td><%= drill.description %></td>
					<td><%= drill.print_skills %></td>
				</tr>
			<% end %>
		</tbody>
	</table>
</div>
