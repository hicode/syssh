<div class="field"><?=str_replace("\n", '<br>', $this->value('schedule/content'))?></div>
<div class="field" style="border:0;">
<?if($this->value('schedule/project')){?>
	事项：<?=$this->value('project/name')?> 
<?}?>
<?if($this->value('schedule/uid')!=$this->user->id){?>
	<br />
	创建人：<?=$this->value('schedule/creater_name')?>
<?}?>
<?if($this->value('schedule/deadline')){?>
	<br />
	截止：<?=$this->value('schedule/deadline')?>
<?}?>
</div>
<?foreach($profiles as $profile){?>
<div class="field profile" id="<?=$profile['id']?>" style="border-bottom: none;border-top:#999 1px solid;"<?if($profile['author']==$this->user->id){?> removable<?}?>><?=$profile['name']?>：<?=$profile['content']?> (<?=$profile['author_name']?>)</div>
<?}?>
<div class="profile hidden" style="text-align:left;">
	<select class="profile-name allow-new" style="width:78%">
		<?=options(array('外出地点','费用金额','费用用途','备注'),NULL)?>
	</select>
	<button>保存</button>
	<br />
	<input type="text" name="profiles[]" style="width:98%" />
</div>