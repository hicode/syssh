<style>
	.column { width: 170px; float: left; padding-bottom: 100px; }
	.portlet { margin: 0 1em 1em 0; }
	.portlet-header { margin: 0.3em; padding-bottom: 4px; padding-left: 0.2em; }
	.portlet-header .ui-icon { float: right; }
	.portlet-content { padding: 0.4em; }
	.ui-sortable-placeholder { border: 1px dotted black; visibility: visible !important; height: 50px !important; }
	.ui-sortable-placeholder * { visibility: hidden; }
</style>
<script>
	$(function() {
		$( ".column" ).sortable({
			connectWith: ".column",
			stop:function(event,ui){
				var taskSort=[];
				$( ".column").each(function(){
					taskSort.push($(this).sortable( "toArray"));
				});
				$.post('/schedule/settaskboardsort',{sortData:taskSort},function(result){
					//console.log(result);
				});
			}
		});
		
		$('.portlet')	.addClass( "ui-widget ui-widget-content ui-helper-clearfix ui-corner-all" )
		.find( ".portlet-header" )
		.addClass( "ui-widget-header ui-corner-all" )
		.prepend( "<span class='ui-icon ui-icon-minusthick'></span>")
		.end();
 
		$('input[name="add[task]"]').click(function(){
			$("#taskboard").createSchedule();
		})

		$( ".column" ).disableSelection();
	});

	$(document).on('click','.portlet',function(){
		var event={id:$(this).attr('id').replace('task_','')}
		$(this).showSchedule(event);
	})
	.on('click','.portlet-header .ui-icon',function(event){
		event.stopPropagation();
		$( this ).toggleClass( "ui-icon-minusthick" ).toggleClass( "ui-icon-plusthick" );
		$( this ).parents( ".portlet:first" ).find( ".portlet-content" ).toggle();
	});

</script>
</div>
<div class="contentTableMenu">
	<div class="right">
		<input type="button" name="add[task]" value="添加" />
	</div>
</div>

<div id="taskboard" class="contentTableBox">
	<? foreach ($task_board as $column) { ?>
		<div class="column">	
			<? foreach ($column as $task) { ?>
				<div class="portlet" id="task_<?= $task['id'] ?>">
					<div class="portlet-header"><?= $task['title'] ?></div>
					<div class="portlet-content"><?= $task['content'] ?></div>
				</div>
			<? } ?>
		</div>
	<? } ?>

</div>